# codex-review: independent code review by Codex, for Claude Code (and humans).
#
# Codex runs unsandboxed with live web search: it may build, run tests, write
# repro scripts and read docs to confirm what it finds. Progress goes to a log
# in the run directory; stdout gets only a header and the final review, so the
# caller's context isn't flooded with Codex's event stream.

usage() {
  cat <<'EOF'
Usage: codex-review [TARGET] [OPTIONS] [FOCUS...]
       codex-review --resume SESSION_ID [OPTIONS] MESSAGE...

Targets (default: --uncommitted when the tree is dirty):
  --uncommitted        staged, unstaged and untracked changes
  --base BRANCH        changes on HEAD since it forked from BRANCH
  --commit SHA         the changes introduced by one commit

Options:
  --model MODEL        default: gpt-6.1-sol
  --effort EFFORT      reasoning effort, default: high
  -h, --help

FOCUS is free text appended to the review brief ("concurrency in the
scheduler", "is the migration reversible?"). --resume continues an earlier
review session with MESSAGE, e.g. to dispute a finding or ask for more depth.
EOF
}

model=gpt-6.1-sol
effort=high
target=
target_arg=
resume=

while [ $# -gt 0 ]; do
  case $1 in
    --uncommitted) target=uncommitted ;;
    --base | --commit)
      target=${1#--}
      target_arg=${2:?$1 needs an argument}
      shift
      ;;
    --resume)
      resume=${2:?--resume needs a session id}
      shift
      ;;
    --model)
      model=${2:?--model needs an argument}
      shift
      ;;
    --effort)
      effort=${2:?--effort needs an argument}
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    -*)
      echo "codex-review: unknown option $1" >&2
      usage >&2
      exit 2
      ;;
    *) break ;;
  esac
  shift
done
focus=$*

root=$(git rev-parse --show-toplevel 2>/dev/null) || {
  echo "codex-review: not inside a git repository" >&2
  exit 1
}
cd "$root" || exit 1

# HEAD, stash, staged blobs, and a content hash of every modified, deleted or
# untracked (non-ignored) file, so edits Codex leaves behind are caught even in
# files that were already dirty, and so are commits, stashes and restaging.
tree_state() {
  printf 'HEAD %s\n' "$(git rev-parse -q --verify HEAD || true)"
  printf 'stash %s\n' "$(git rev-parse -q --verify refs/stash || true)"
  git diff-index --cached --no-renames HEAD 2>/dev/null | sed 's/^/staged /' || true
  git ls-files -z --modified --others --exclude-standard | sort -zu |
    while IFS= read -r -d '' f; do
      if [ -L "$f" ]; then
        printf 'symlink:%s  %s\n' "$(readlink -- "$f")" "$f"
      elif [ -f "$f" ]; then
        printf '%s  %s\n' "$(sha256sum <"$f" | cut -d' ' -f1)" "$f"
      elif [ -e "$f" ]; then
        printf 'other  %s\n' "$f"
      else
        printf 'deleted  %s\n' "$f"
      fi
    done
}

state=${XDG_STATE_HOME:-$HOME/.local/state}/codex-review
mkdir -p "$state"
run=$(mktemp -d "$state/$(date +%Y%m%d-%H%M%S)-$(basename "$root").XXXXXX")
scratch=$run/scratch
mkdir "$scratch"
tree_state >"$run/tree-before"

common=(
  --dangerously-bypass-approvals-and-sandbox
  --model "$model"
  -c "model_reasoning_effort=\"$effort\""
  -c 'web_search="live"'
  --json
  --output-last-message "$run/review.md"
)

if [ -n "$resume" ]; then
  [ -n "$focus" ] || {
    echo "codex-review: --resume needs a MESSAGE" >&2
    exit 2
  }
  label="follow-up on $resume"
  printf '%s\n' "$focus" >"$run/prompt.md"
  cmd=(codex exec resume "${common[@]}" "$resume" -)
else
  if [ -z "$target" ]; then
    if [ -n "$(git status --porcelain)" ]; then
      target=uncommitted
    else
      echo "codex-review: working tree is clean; pass --base BRANCH or --commit SHA" >&2
      exit 2
    fi
  fi
  case $target in
    uncommitted)
      label="uncommitted changes"
      how="The changes are uncommitted: see \`git status\`, \`git diff HEAD\` (staged and unstaged) and read untracked files directly."
      ;;
    base)
      mb=$(git merge-base HEAD "$target_arg") || {
        echo "codex-review: no merge base between HEAD and $target_arg" >&2
        exit 1
      }
      label="HEAD against $target_arg"
      how="The changes are the commits on HEAD since it forked from \`$target_arg\` (merge base $mb): see \`git log $mb..HEAD\` and \`git diff $mb HEAD\`. Uncommitted changes, if any, are not part of the review."
      ;;
    commit)
      sha=$(git rev-parse --verify "$target_arg^{commit}") || exit 1
      label="commit ${sha:0:12}"
      how="The change is commit $sha: see \`git show $sha\`. The working tree may be at a later state; use \`git show $sha:<path>\` or a worktree under the scratch directory when you need the tree as of that commit."
      ;;
  esac

  cat >"$run/prompt.md" <<EOF
You are an independent reviewer of code changes in the repository at $root.
Another agent (Claude) is responsible for these changes; it will verify your
findings and act on them, so precision matters more than volume.

## What to review

$how

## Focus

${focus:-None given: do a general review for correctness, security, data loss, concurrency, error handling, performance regressions and missing tests.}

## How to work

You have full, unsandboxed access to this machine and the network, and live
web search. Use whatever helps you find real problems and confirm them:

- Read beyond the diff: callers, callees, tests, configuration, docs.
- Build the project; run its tests, linters and type checkers.
- Write throwaway tests or repro scripts to prove or disprove a suspected bug.
- Search the web and official docs for API behaviour, known issues and
  version-specific changes instead of guessing.

A finding you reproduced is worth more than one you suspect.

## Leave the user's work as you found it

The code under review may exist only in the working tree. Do not edit, revert,
stage, stash, commit, reset or check out anything there, and do not push. Put
scratch files, repro scripts and extra worktrees in $scratch. If a test must
live inside the repository to compile, delete it when you are done. Build
output that git ignores is fine. Express fixes as suggested patches in the
report, not as edits.

## Report

Your final message is the review, in Markdown:

1. A one-line verdict.
2. Findings, most severe first. For each: severity (critical, high, medium,
   low), \`file:line\`, the defect, a concrete failure scenario, evidence (what
   you ran and what happened, or "not reproduced"), and a suggested fix.
3. Checked and fine: what you verified that holds up, briefly.
4. Not checked: anything you could not verify, and why.

If you find nothing that matters, say so plainly. Skip style nits unless they
hide a bug.
EOF
  cmd=(codex exec "${common[@]}" -)
fi

echo "== codex-review: $label | $model ($effort) =="
echo "run dir: $run"

status=0
"${cmd[@]}" <"$run/prompt.md" >"$run/events.jsonl" 2>"$run/stderr.log" || status=$?

session=$(grep -om1 '"thread_id":"[^"]*"' "$run/events.jsonl" | cut -d'"' -f4 || true)
session=${session:-$resume}
echo "session: ${session:-unknown}"
[ -n "$session" ] && echo "follow up: codex-review --resume $session \"...\""

tree_state >"$run/tree-after"
if ! cmp -s "$run/tree-before" "$run/tree-after"; then
  echo
  echo "WARNING: the working tree changed during the review (before/after):"
  diff "$run/tree-before" "$run/tree-after" | grep '^[<>]' || true
fi

if [ "$status" -ne 0 ] || [ ! -s "$run/review.md" ]; then
  echo
  echo "codex exited with status $status and no review. Last log lines:"
  tail -n 20 "$run/stderr.log"
  exit "$((status ? status : 1))"
fi

echo
cat "$run/review.md"
