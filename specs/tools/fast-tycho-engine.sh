#!/usr/bin/env bash
set -euo pipefail

# Fast incremental build + hot-patch for KRE (Playwright)
# - Rebuild only changed Tycho bundles (or specified modules)
# - Patch the extracted KRE app's plugin jars in-place with updated classes
# - Clear p2 binary cache to ensure the changes take effect
# - Optionally launch KRE to verify the change
#
# Location: specs/tools/fast-tycho-engine.sh
# Usage examples:
#   specs/tools/fast-tycho-engine.sh               # auto-detect changed modules under source/*
#   specs/tools/fast-tycho-engine.sh -m com.kms.katalon.core.webui
#   specs/tools/fast-tycho-engine.sh -m com.kms.katalon.core.webui -r
#   specs/tools/fast-tycho-engine.sh -r -p "Test Suites/healthcare-tests - TS_RegressionTest"
#
# Notes:
# - Requires that KRE has already been built and extracted (e.g., via specs/tools/build-studio-package.sh).
#   The script will
#   try to extract the latest macOS arm64 engine if not found.
# - We preserve jar filenames to avoid bundles.info mismatches and instead
#   update class entries inside the jars, then clear p2 binary cache.

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
SRC_DIR="${ROOT_DIR}/source"
REPO_DIR="${SRC_DIR}/com.kms.katalon.repo"
DIST_DIR="${ROOT_DIR}/dist"

PORT="9999"
MODULES=""     # comma-separated list. If empty, auto-detect from VCS changes
RUN_AFTER=false # launch KRE after patch
PREPARE_ONLY=false
SUITE_PATH="Test Suites/healthcare-tests - TS_RegressionTest"
PROJECT_PATH="/Users/hai.nguyen/Katalon Studio/test-playwright"
JETTY_PID=""
JETTY_STARTED=false
JETTY_LOG="${ROOT_DIR}/tmp/fast-tycho-jetty.log"

usage() {
  cat <<USAGE
Fast Tycho engine build + hot-patch
Usage: $0 [-m mod1,mod2] [-r] [--prepare] [-s <suitePath>] [-p <projectPath>]
  -m   Comma-separated module ids to build (e.g., com.kms.katalon.core.webui)
       Default: auto-detect changed modules under source/*
  -r   Run KRE (Playwright) after patch
  --prepare  Prepare environment only (build local P2 + start Jetty + install target); no module build
  -s   Test suite path for -r (default: "$SUITE_PATH")
  -p   Project path for -r (default: "$PROJECT_PATH")
USAGE
}

OPTS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    -m) MODULES="$2"; shift 2 ;;
    -r) RUN_AFTER=true; shift ;;
    --prepare) PREPARE_ONLY=true; shift ;;
    -s) SUITE_PATH="$2"; shift 2 ;;
    -p) PROJECT_PATH="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1"; usage; exit 2 ;;
  esac
done

cleanup() {
  if $JETTY_STARTED && [[ -n "${JETTY_PID}" ]]; then
    if kill -0 "${JETTY_PID}" 2>/dev/null; then
      echo "[fast] Stopping local P2 Jetty (pid=${JETTY_PID})"
      kill "${JETTY_PID}" 2>/dev/null || true
    fi
  fi
}

ensure_java17() {
  if command -v java >/dev/null 2>&1 && java -version 2>&1 | sed -n '1p' | grep -q '17\.'; then
    return
  fi
  if command -v brew >/dev/null 2>&1 && [[ -d "$(brew --prefix openjdk@17 2>/dev/null || true)" ]]; then
    export JAVA_HOME="$(brew --prefix openjdk@17)/libexec/openjdk.jdk/Contents/Home"
    export PATH="$JAVA_HOME/bin:$PATH"
  fi
  java -version >/dev/null 2>&1 || { echo "Java 17 not available in PATH" >&2; exit 1; }
}

ensure_jetty() {
  if lsof -i TCP:"${PORT}" -sTCP:LISTEN >/dev/null 2>&1; then
    echo "[fast] Reusing existing P2 Jetty on :$PORT"
    return
  fi
  mkdir -p "$(dirname "${JETTY_LOG}")"
  : > "${JETTY_LOG}"
  echo "[fast] Starting local P2 Jetty on :$PORT"
  (cd "$REPO_DIR" && mvn -q -Dmaven.internal.username=${MAVEN_INTERNAL_USERNAME:-} -Dmaven.internal.password=${MAVEN_INTERNAL_PASSWORD:-} -s settings.xml p2:site && mvn -q -Djetty.port="$PORT" jetty:run >>"${JETTY_LOG}" 2>&1) &
  JETTY_PID=$!
  JETTY_STARTED=true
  trap cleanup EXIT
  # Wait until the p2 site root exists and content.jar is downloadable
  for i in {1..90}; do
    if curl -fsS "http://localhost:${PORT}/site/content.jar" >/dev/null 2>&1; then
      echo "[fast] Jetty ready on :$PORT"
      return
    fi
    if ! kill -0 "${JETTY_PID}" 2>/dev/null; then
      echo "[fast] Jetty process exited early; see ${JETTY_LOG}" >&2
      tail -n 50 "${JETTY_LOG}" >&2 || true
      exit 1
    fi
    sleep 1
  done
  echo "[fast] Jetty did not become ready after 90s; see ${JETTY_LOG}" >&2
  tail -n 50 "${JETTY_LOG}" >&2 || true
  exit 1
}

auto_detect_modules() {
  # Look for changed files under source/* and map to top-level module dirs
  local diffs
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    diffs=$(git status --porcelain | awk '{print $2}')
  else
    diffs=""
  fi
  local mods=()
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    [[ "$f" != source/* ]] && continue
    local top="${f#source/}"
    top="${top%%/*}"
    # Only include actual Tycho modules that contain a pom.xml
    if [[ -f "$SRC_DIR/$top/pom.xml" ]]; then
      mods+=("$top")
    fi
  done <<<"$diffs"

  # Unique + join by comma
  if [[ ${#mods[@]} -gt 0 ]]; then
    MODULES=$(printf '%s\n' "${mods[@]}" | sort -u | paste -sd, -)
  else
    MODULES=""
  fi
}

extract_kre_if_needed() {
  local app_bin="${DIST_DIR}/KRE-macOS-arm64/Katalon Studio Engine.app/Contents/MacOS/katalonc"
  if [[ -x "$app_bin" ]]; then return; fi
  local tgz=$(ls -t ${SRC_DIR}/com.kms.katalon.product.engine/target/products/Katalon_Studio_Engine_MacOS_arm64.tar.gz 2>/dev/null | head -n1 || true)
  [[ -f "$tgz" ]] || {
    echo "[fast] No baseline Engine build to patch (engine tarball not found)." >&2
    echo "[fast] First-time setup: run specs/tools/build-studio-package.sh to produce Studio/Engine products." >&2
    echo "[fast] After that, re-run this script to hot-patch the extracted app under dist/." >&2
    exit 3
  }
  mkdir -p "${DIST_DIR}/KRE-macOS-arm64"
  tar -xzf "$tgz" -C "${DIST_DIR}/KRE-macOS-arm64"
}

patch_app_for_module() {
  local module="$1"
  local classes_dir="$SRC_DIR/$module/target/classes"
  local plugins_dir="${DIST_DIR}/KRE-macOS-arm64/Katalon Studio Engine.app/Contents/Eclipse/plugins"
  [[ -d "$classes_dir" ]] || { echo "[fast] No classes for $module; was the module built?"; return 1; }
  [[ -d "$plugins_dir" ]] || { echo "[fast] Engine plugins dir not found: $plugins_dir" >&2; return 2; }

  local jar
  jar=$(ls -t "$plugins_dir/$module"_*.jar 2>/dev/null | head -n1 || true)
  [[ -f "$jar" ]] || {
    echo "[fast] Plugin jar not found in extracted Engine app for module: $module" >&2
    echo "[fast] Hint: if this is a fresh repo or no full build has run, execute: specs/tools/build-studio-package.sh" >&2
    echo "[fast] Then re-run fast-tycho-engine.sh to apply the hot-patch." >&2
    return 3
  }

  echo "[fast] Patching jar: $(basename "$jar") with classes from $module"
  (cd "$classes_dir" && zip -qr -u "$jar" .)

  # Clear p2 binary cache so Equinox reloads jar content
  local cache_dir="${DIST_DIR}/KRE-macOS-arm64/Katalon Studio Engine.app/Contents/Eclipse/p2/org.eclipse.equinox.p2.core/cache/binary"
  rm -rf "$cache_dir" 2>/dev/null || true
}

run_kre() {
  local api_key="${KATALON_API_KEY:-${API_KEY:-}}"
  if [[ -z "$api_key" && -f "${ROOT_DIR}/tools/.api-key" ]]; then
    api_key=$(sed -n '1p' "${ROOT_DIR}/tools/.api-key" | tr -d '[:space:]')
  fi
  : "${api_key:=fda8d7dd-81e0-452c-9fb9-0c5bdb536a9f}"
  KATALON_API_KEY="$api_key" \
  PROJECT_PATH="$PROJECT_PATH" \
  TEST_SUITE_PATH="$SUITE_PATH" \
    "${ROOT_DIR}/specs/playwright_engine/scripts/run-kre-playwright.sh"
}

main() {
  ensure_java17
  ensure_jetty
  ensure_target_installed
  check_playwright_units || true

  if $PREPARE_ONLY; then
    echo "[fast] Preparation complete. You can now run with -m <module> to hot-patch."
    exit 0
  fi

  if [[ -z "$MODULES" ]]; then
    auto_detect_modules
  fi
  if [[ -z "$MODULES" ]]; then
    echo "[fast] No modules detected as changed. Use -m to specify."
    exit 0
  fi

  IFS=',' read -r -a arr <<< "$MODULES"
  echo "[fast] Will build modules: ${arr[*]}"

  # Build only requested modules and their deps (am) with tests skipped
  (cd "$SRC_DIR" && mvn -q -T 1C -DskipTests -Dtycho.localArtifacts=ignore -pl "${MODULES}" -am package)

  extract_kre_if_needed
  for m in "${arr[@]}"; do
    patch_app_for_module "$m"
  done

  if $RUN_AFTER; then
    run_kre
  else
    echo "[fast] Done. You can now run KRE via: specs/playwright_engine/scripts/run-kre-playwright.sh"
  fi
}

ensure_target_installed() {
  # Tycho resolves the target by artifact coordinates; ensure it’s installed locally
  if [[ -f "$HOME/.m2/repository/com/kms/com.kms.katalon.target/1.0.0-SNAPSHOT/com.kms.katalon.target-1.0.0-SNAPSHOT.target" ]]; then
    return
  fi
  echo "[fast] Installing target definition artifact (one-time)"
  (cd "$SRC_DIR/com.kms.katalon.target" && mvn -q -DskipTests install)
}

check_playwright_units() {
  if ! curl -fsS "http://localhost:${PORT}/site/content.jar" >/dev/null 2>&1; then
    echo "[fast] P2 site is not reachable on http://localhost:${PORT}/site" >&2
    return 1
  fi
  # Quick probe by listing available IUs via composite metadata
  if curl -fsS "http://localhost:${PORT}/site/content.xml" 2>/dev/null | grep -q "com.microsoft.playwright.driver-bundle"; then
    return 0
  fi
  echo "[fast] Playwright driver units not found in local P2. Ensure credentials (MAVEN_INTERNAL_USERNAME/PASSWORD) are set so p2:site can fetch them." >&2
  return 1
}

main "$@"
