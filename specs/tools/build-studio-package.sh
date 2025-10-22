#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
# Capture whether the user explicitly set EDITION_FREE before running the script
USER_SET_EDITION_FREE="${EDITION_FREE-}"
REPO_DIR="${ROOT_DIR}/source/com.kms.katalon.repo"
SRC_DIR="${ROOT_DIR}/source"
DIST_DIR="${ROOT_DIR}/dist"

# Defaults
PORT="9999"
PLAYWRIGHT_DEFAULT="true"   # Kept for backward compat; CI does not set these flags explicitly

# CI parity env placeholders (mirrors _build.yaml)
ARTIFACT_DIR_DEFAULT="${ROOT_DIR}/artifact"

# Ensure Java 17 like CI (uses setup-java). Mirrors tools/build-engine-only.sh.
ensure_java17() {
  if command -v java >/dev/null 2>&1 && java -version 2>&1 | sed -n '1p' | grep -q '17\.'; then
    echo "Java is already 17: $(java -version 2>&1 | sed -n '1p')"; return
  fi
  if command -v brew >/dev/null 2>&1 && [[ -d "$(brew --prefix openjdk@17)" ]]; then
    export JAVA_HOME="$(brew --prefix openjdk@17)/libexec/openjdk.jdk/Contents/Home"
    export PATH="$JAVA_HOME/bin:$PATH"
    echo "JAVA_HOME set to $JAVA_HOME"
  fi
  java -version >/dev/null 2>&1 || { echo "Java 17 not available in PATH" >&2; exit 1; }
}

ensure_git_lfs() {
  if ! command -v git >/dev/null 2>&1; then
    echo "git is required" >&2; exit 1
  fi
  if ! git lfs version >/dev/null 2>&1; then
    echo "git-lfs not found. Please install Git LFS (e.g., 'brew install git-lfs') and rerun." >&2
    exit 2
  fi
  echo "Ensuring Git LFS content (resources/lib jars) is present..."
  git lfs install --force >/dev/null 2>&1 || true
  # Pull only large binary libs used in Tycho plugins to avoid full LFS sync
  git lfs pull --include="source/**/resources/lib/**" --exclude="" || {
    echo "git lfs pull failed." >&2; exit 3;
  }
  # Detect unresolved LFS pointers by signature instead of size (avoid false positives on tiny valid jars)
  local any_pointer
  any_pointer=$(find "${ROOT_DIR}/source" -type f -path "*/resources/lib/*.jar" \
    -exec sh -c 'head -c 200 "$1" 2>/dev/null | grep -q "version https://git-lfs.github.com/spec/v1" && printf "%s\n" "$1"' _ {} \; -quit 2>/dev/null || true)
  if [[ -n "$any_pointer" ]]; then
    echo "Detected unresolved LFS pointer file: $any_pointer" >&2
    echo "Please ensure network access and rerun: git lfs pull --include 'source/**/resources/lib/**'" >&2
    exit 3
  fi
}

prepare_ci_env() {
  # Mirror steps in .github/workflows/_build.yaml → prepare_github_actions_envs.py
  # Provide envs expected by that script, then source the generated variables into this shell
  export BUILD_ARTIFACTSTAGINGDIRECTORY="${ARTIFACT_DIR_DEFAULT}"
  export BUILD_REPOSITORY_LOCALPATH="${ROOT_DIR}"
  export BUILD_SOURCEBRANCHNAME="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo local)"
  export BUILD_SOURCEVERSION="$(git rev-parse HEAD 2>/dev/null || echo 0000000000000000000000000000000000000000)"

  # Python deps are lightweight; install if pip is available
  if command -v python3 >/dev/null 2>&1; then
    if command -v pip3 >/dev/null 2>&1; then
      pip3 -q install -r "${ROOT_DIR}/build/requirements.txt" || true
    fi
    (
      cd "${ROOT_DIR}"
      python3 build/scripts/prepare_github_actions_envs.py
    )
    # Use a local env file like GITHUB_ENV and parse it into exports (spaces-safe)
    export GITHUB_ENV="${ROOT_DIR}/.github_env_local"
    : > "$GITHUB_ENV"
    if [[ -f "${ROOT_DIR}/variables.sh" ]]; then
      bash "${ROOT_DIR}/variables.sh" >/dev/null 2>&1 || true
      # Re‑export key=value lines from $GITHUB_ENV; values may contain spaces
      while IFS= read -r line; do
        [[ -z "$line" || "$line" = \#* ]] && continue
        key="${line%%=*}"
        val="${line#*=}"
        # Trim possible CR
        val="${val%$'\r'}"
        export "$key"="$val"
      done < "$GITHUB_ENV"
    fi
  else
    echo "python3 not found; proceeding without CI-derived variables (BUILD_PROFILE=all)." >&2
  fi

  # Sensible defaults if CI env script was skipped
  : "${BUILD_PROFILE:=all}"
  : "${EDITION_ENTERPRISE:=true}"
  : "${EDITION_FREE:=false}"
  # Local default: build only Enterprise unless the user explicitly set EDITION_FREE before invoking
  if [[ -z "${USER_SET_EDITION_FREE}" ]]; then
    EDITION_FREE="false"
  fi
  : "${ENTERPRISE_PRODUCT_ID:=com.kms.katalon.product}"
  : "${ENGINE_PRODUCT_ID:=com.kms.katalon.product.engine}"
  : "${FREE_PRODUCT_ID:=com.kms.katalon.product.free}"
  : "${ARTIFACT_DIR:=${ARTIFACT_DIR_DEFAULT}}"
}

ensure_java17
ensure_git_lfs
prepare_ci_env
echo "[1/4] Building local P2 repository (com.kms.katalon.repo)"
pushd "$REPO_DIR" >/dev/null
mvn -q -Dmaven.internal.username=${MAVEN_INTERNAL_USERNAME:-} -Dmaven.internal.password=${MAVEN_INTERNAL_PASSWORD:-} -s settings.xml p2:site
echo "[2/4] Starting local P2 Jetty on port ${PORT}"
## Proactively kill any previous Jetty bound to the port
if command -v lsof >/dev/null 2>&1; then
  old_pids=$(lsof -t -i TCP:"${PORT}" -sTCP:LISTEN || true)
  if [[ -n "$old_pids" ]]; then
    echo "Found existing process(es) on :${PORT}: $old_pids — killing"
    kill $old_pids || true
    sleep 1
  fi
fi
(
  mvn -q -Djetty.port="${PORT}" jetty:run
) &
JETTY_PID=$!

cleanup() {
  if kill -0 "$JETTY_PID" 2>/dev/null; then
    echo "Stopping Jetty (pid=$JETTY_PID)"
    kill "$JETTY_PID" || true
  fi
}
trap cleanup EXIT
popd >/dev/null

# Wait for Jetty to be ready
echo "[2/4] Waiting for P2 repo to be ready..."
for i in {1..60}; do
  if curl -fsS "http://localhost:${PORT}/" >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

echo "[3/4] Building products via Tycho (profile: ${BUILD_PROFILE})"
pushd "$SRC_DIR" >/dev/null

# Build both KSE and KRE products; pass flags to make Playwright default if desired
MVN_FLAGS=""
if [[ "${PLAYWRIGHT_DEFAULT}" == "true" ]]; then
  MVN_FLAGS="-Dkse.playwright.default=true -Dkre.playwright.default=true"
fi

# Align with CI: include -fae and CI-computed build profile
mvn -q -U clean verify -P "${BUILD_PROFILE}" -fae ${MVN_FLAGS}

# Build API docs like CI (skip tests)
if [[ -d "${SRC_DIR}/com.kms.katalon.apidocs" ]]; then
  (cd "${SRC_DIR}/com.kms.katalon.apidocs" && mvn -q -DskipTests=true -T 2 clean verify)
fi

echo "[4/4] Artifacts ready under:"
echo "  - ${SRC_DIR}/com.kms.katalon.product/target/products"
echo "  - ${SRC_DIR}/com.kms.katalon.product.engine/target/products"

# Stage artifacts like CI so packaging scripts can consume them
echo "[post] Staging artifacts to ${ARTIFACT_DIR}"
mkdir -p "${ARTIFACT_DIR}"
if [[ "${EDITION_ENTERPRISE}" == "true" ]]; then
  mkdir -p "${ARTIFACT_DIR}/enterprise"
  cp -f ${SRC_DIR}/${ENTERPRISE_PRODUCT_ID}/target/products/*.{zip,tar.gz} "${ARTIFACT_DIR}/enterprise/" 2>/dev/null || true
  cp -f ${SRC_DIR}/${ENGINE_PRODUCT_ID}/target/products/*.{zip,tar.gz} "${ARTIFACT_DIR}/enterprise/" 2>/dev/null || true
fi
if [[ "${EDITION_FREE}" == "true" ]]; then
  mkdir -p "${ARTIFACT_DIR}/free"
  cp -f ${SRC_DIR}/${FREE_PRODUCT_ID}/target/products/*.{zip,tar.gz} "${ARTIFACT_DIR}/free/" 2>/dev/null || true
fi

# Also keep local extraction convenience for macOS devs
echo "[post] Extracting apps to ${DIST_DIR} (developer convenience)"
mkdir -p "${DIST_DIR}/KSE-macOS-arm64" "${DIST_DIR}/KRE-macOS-arm64"
KSE_TGZ=$(ls -t ${SRC_DIR}/${ENTERPRISE_PRODUCT_ID}/target/products/Katalon_Studio_*_MacOS*_arm64.tar.gz 2>/dev/null | head -n1 || true)
KRE_TGZ=$(ls -t ${SRC_DIR}/${ENGINE_PRODUCT_ID}/target/products/Katalon_Studio_Engine_MacOS_arm64.tar.gz 2>/dev/null | head -n1 || true)
if [[ -n "$KSE_TGZ" ]]; then rm -rf "${DIST_DIR}/KSE-macOS-arm64"/*; tar -xzf "$KSE_TGZ" -C "${DIST_DIR}/KSE-macOS-arm64"; fi
if [[ -n "$KRE_TGZ" ]]; then rm -rf "${DIST_DIR}/KRE-macOS-arm64"/*; tar -xzf "$KRE_TGZ" -C "${DIST_DIR}/KRE-macOS-arm64"; fi

echo "[post] To launch Studio UI (macOS):"
if ls "${DIST_DIR}/KSE-macOS-arm64"/Katalon\ Studio*.app >/dev/null 2>&1; then
  APP_PATH=$(ls -t "${DIST_DIR}/KSE-macOS-arm64"/Katalon\ Studio*.app | head -n1)
  echo "  open \"$APP_PATH\""
fi

popd >/dev/null
echo "Done."
