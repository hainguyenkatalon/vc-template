#!/usr/bin/env python3
import argparse
import subprocess
import sys
import textwrap
from pathlib import Path
from typing import Optional
from datetime import datetime


def run(cmd, input_text=None):
    return subprocess.run(cmd, input=input_text, text=True, capture_output=True)


def git_branch():
    """Return the current git branch name.

    Handles non-worktree clones, detached HEAD, and common CI envs.
    Fallbacks (in order):
    - `git rev-parse --abbrev-ref HEAD`
    - `git branch --show-current`
    - `git symbolic-ref --quiet --short HEAD`
    - CI env vars (GITHUB_REF_NAME, GITHUB_HEAD_REF, CI_COMMIT_REF_NAME, BRANCH_NAME,
      BUILDKITE_BRANCH, CIRCLE_BRANCH, GIT_BRANCH)
    - Local branch pointing at HEAD (if unique)
    - `detached-<shortsha>`
    """

    # 1) Standard branch lookup
    r = run(["git", "rev-parse", "--abbrev-ref", "HEAD"])
    b = (r.stdout or "").strip()
    if r.returncode == 0 and b and b != "HEAD":
        return b

    # 2) Modern Git helper
    r = run(["git", "branch", "--show-current"])
    b = (r.stdout or "").strip()
    if r.returncode == 0 and b:
        return b

    # 3) Symbolic ref (quiet)
    r = run(["git", "symbolic-ref", "--quiet", "--short", "HEAD"])
    b = (r.stdout or "").strip()
    if r.returncode == 0 and b:
        return b

    # 4) CI environment fallbacks
    import os
    for key in (
        "GITHUB_REF_NAME",  # branch or tag name
        "GITHUB_HEAD_REF",  # PR source branch
        "CI_COMMIT_REF_NAME",  # GitLab
        "BRANCH_NAME",  # Jenkins
        "BUILDKITE_BRANCH",
        "CIRCLE_BRANCH",
        "GIT_BRANCH",
    ):
        val = os.environ.get(key, "").strip()
        if val:
            return val

    # 5) Try to find a local branch that points at HEAD (unique)
    r = run([
        "git",
        "for-each-ref",
        "--format=%(refname:short)",
        "--points-at",
        "HEAD",
        "refs/heads",
    ])
    candidates = [ln.strip() for ln in (r.stdout or "").splitlines() if ln.strip()]
    if r.returncode == 0 and len(candidates) == 1:
        return candidates[0]

    # 6) As a last resort, create a deterministic name for detached state
    r = run(["git", "rev-parse", "--short", "HEAD"])
    short = (r.stdout or "").strip() or "unknown"
    fallback = f"detached-{short}"
    print(
        f"[codex_tools] Branch not detected (detached or non-worktree). Using '{fallback}'.",
        file=sys.stderr,
    )
    return fallback


def spec_dir_for_branch(branch: str) -> Path:
    return Path("specs") / branch


PROMPT = textwrap.dedent(
    """
    Continue working on this branch.
    """
).strip()


def codex_exec(
    prompt: str,
    model: str,
    log_file: Path,
    output_path: Optional[Path] = None,
    reasoning_effort: str = "medium",
):
    flags = ["--skip-git-repo-check", "--yolo"]
    cmd = [
        "codex",
        "exec",
        "--skip-git-repo-check",
        "--yolo",
        "--model",
        model,
        "-c",
        "tools.web_search=true",
        "-c",
        f"reasoning_effort={reasoning_effort}",
        prompt
    ]
    with open(log_file, "a") as out:
        p = subprocess.Popen(cmd, stdin=subprocess.PIPE, stdout=out, stderr=out, text=True)
        p.wait()
        return p.returncode


def git_changes_pending() -> bool:
    r = run(["git", "status", "--porcelain"])
    return bool((r.stdout or "").strip())


def git_commit(msg: str):
    run(["git", "add", "-A"])
    run(["git", "commit", "-m", msg])


def loop(iterations: int, model: str, output_path: Optional[Path], reasoning_effort: str = "medium"):
    branch = git_branch()
    spec = spec_dir_for_branch(branch)
    spec.mkdir(parents=True, exist_ok=True)
    log_dir = spec / "logs"
    log_dir.mkdir(parents=True, exist_ok=True)
    ts = datetime.now().strftime("%Y%m%d-%H%M%S")
    log_file = log_dir / f"loop-{ts}.log"
    # Default output file (if not provided): keep alongside logs
    if output_path is None:
        output_path = log_dir / f"final-output-{ts}.json"
    # Ensure parent exists (defensive if user passed a custom path)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    for i in range(1, iterations + 1):
        if (spec / "STUCK.md").exists():
            with open(log_file, "a") as f:
                f.write("[codex_tools] STUCK.md present — stop.\n")
            break
        with open(log_file, "a") as f:
            f.write(f"[codex_tools] iteration {i}/{iterations}\n")
        rc = codex_exec(PROMPT, model, log_file, output_path, reasoning_effort)
        # if git_changes_pending():
        #     git_commit(f"chore(loop): iteration {i}/{iterations} updates (auto)")
    print(f"[codex_tools] log: {log_file}")
    print(f"[codex_tools] output: {output_path}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--iterations", "-n", type=int, default=5)
    ap.add_argument("--model", "-m", default="gpt-5")
    ap.add_argument(
        "--reasoning-effort", "-r",
        default="high",
        choices=["low", "medium", "high", "auto"],
    )
    ap.add_argument("--output", "-o", type=Path, help="Write agent final output to file (default: specs/<branch>/logs/final-output-<timestamp>.json)")
    args = ap.parse_args()
    loop(args.iterations, args.model, args.output, args.reasoning_effort)


if __name__ == "__main__":
    main()
