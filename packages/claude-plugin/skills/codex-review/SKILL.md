---
name: codex-review
description: Consult OpenAI Codex (GPT-6.1 Sol, high effort, unsandboxed with web search) for an independent code review or a free-form second opinion (design, debugging, research, any question), then verify its answer yourself. Use when the user asks for a Codex review, to consult/ask Codex, or for a second opinion from Codex/GPT/Sol; or when they invoke /codex-review.
argument-hint: "[--uncommitted | --base BRANCH | --commit SHA | --ask] [focus or question...]"
---

# Codex review and consultation

`@codexReview@/bin/codex-review` hands a change (review) or a question
(`--ask`) to Codex and prints only its final answer. Codex runs with **full permissions**:
no sandbox, no approval prompts, live web search. It can build, run tests,
write repro scripts and read docs. That is deliberate; do not add sandbox or
read-only flags. The script tells Codex to keep its scratch work out of the
user's working tree and warns if anything there changed anyway.

Model and effort are pinned to `gpt-6.1-sol` / `high`. Only pass `--model` or
`--effort` when the user asks for something else.

Each run spends the user's OpenAI quota. Run it when the user asks for it (or
invokes this skill), not as a routine step of your own.

## 1. Pick the mode and target

A request to review code changes is a review. Anything else is a
consultation: a design or approach question, a debugging hunch, research, or
a doubt about something already in the code. Use `--ask` for those.

### Consultation

`--ask` takes the question as the whole brief. Codex starts in the current
directory (the repository root inside git) and works outside git too. Write a
self-contained question: the problem, absolute paths to the relevant files,
what you already know or tried, the options you are weighing, and what answer
you need. State it neutrally, so Codex can push back on the premise. Pass long
questions on stdin with a quoted heredoc to avoid shell interpolation:

```sh
@codexReview@/bin/codex-review --ask - <<'Q'
question...
Q
```

### Review

Use what the user gave in `$ARGUMENTS`. Without a target:

- uncommitted changes exist → `--uncommitted`
- clean tree on a feature branch → `--base <default branch>`
- clean tree on the default branch → `--commit HEAD`

Any remaining text is the focus: pass it through, and add what you know that
Codex should check (the risky part, the intent of the change, a doubt you have).
Keep it short; Codex reads the code itself.

## 2. Run it in the background

A review takes minutes and can take much longer, so always use Bash with
`run_in_background: true` and `timeout: 7200000`, from the repository:

```sh
@codexReview@/bin/codex-review --base master "focus text"
```

Tell the user it is running, then wait for the completion notification: don't
poll, and don't start editing the files under review meanwhile (the script
flags working-tree changes made during the run, yours included).

The output starts with the run directory and the session id, then the review.
The run directory holds `prompt.md`, `review.md`, the event log
`events.jsonl`, `stderr.log`, and `scratch/` with any repro scripts Codex wrote.
The final answer is saved as `review.md` in both modes. If the run failed,
read the `stderr.log` tail it printed and report it.

## 3. Verify, then report

Codex can be wrong. For every finding, check the cited code yourself, and rerun
its repro from `scratch/` when there is one. For a consultation, check its
load-bearing claims the same way and give the user its answer with your own
view, including where you disagree. For a review, report to the user:

- **Confirmed**: findings you verified, with `file:line` and the fix.
- **Disputed**: findings you think are wrong, with your reasoning.
- **Unverified**: what you could not settle either way.

Lead with Codex's verdict, mention anything it listed as not checked, and
relay any working-tree warning verbatim. Do not apply fixes unless the user
asked for that.

## Follow-ups

To dispute a finding, ask for more depth, or have Codex re-check after a fix,
resume the same session (it keeps its context). This works the same for
reviews and consultations; a new, unrelated question gets a fresh `--ask`:

```sh
@codexReview@/bin/codex-review --resume <session id> "message"
```

Run follow-ups in the background too.
