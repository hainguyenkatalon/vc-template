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
    r = run(["git", "rev-parse", "--abbrev-ref", "HEAD"])
    b = (r.stdout or "").strip()
    if not b or b == "HEAD":
        print("[codex_tools] Unable to determine branch; run inside a git worktree.", file=sys.stderr)
        sys.exit(2)
    return b


def spec_dir_for_branch(branch: str) -> Path:
    return Path("specs") / branch


PROMPT = textwrap.dedent(
    """
    Continue working on this branch.
    """
).strip()


def codex_exec(prompt: str, model: str, log_file: Path, output_path: Optional[Path] = None):
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
        "reasoning_effort=high",
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


def loop(iterations: int, model: str, output_path: Optional[Path]):
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
        rc = codex_exec(PROMPT, model, log_file, output_path)
        # if git_changes_pending():
        #     git_commit(f"chore(loop): iteration {i}/{iterations} updates (auto)")
    print(f"[codex_tools] log: {log_file}")
    print(f"[codex_tools] output: {output_path}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--iterations", "-n", type=int, default=5)
    ap.add_argument("--model", default="gpt-5")
    ap.add_argument("--output", "-o", type=Path, help="Write agent final output to file (default: specs/<branch>/logs/final-output-<timestamp>.json)")
    args = ap.parse_args()
    loop(args.iterations, args.model, args.output)


if __name__ == "__main__":
    main()
