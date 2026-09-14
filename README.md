# bork

`bork` does what it says: it breaks things. Point it at a git repo and it
spawns a swarm of hostile AI agents whose only job is to find real,
demonstrable ways the code fails — then reports what they broke.

```
$ cd ~/repos/myproject
$ bork --last-commit
[bork] target: myproject @ diff HEAD~1..HEAD (worktree at a1b2c3d4e5f6)
[bork] triage: analyzing /home/paul/repos/myproject ...
[bork] hunt plan
agent   bug class                   focus
------------------------------------------------------------------------------
#1      silent-fail-open            src/decide.go error/cancel paths
#2      zero-value-keep             src/decide.go unmarshalling
#3      prompt-size-and-injection   src/decide.go prompt construction
[bork] run: 20260914-144915-myproject  (3 hunters)
[bork] spawning 3 hunters (timeout 15m each) ...
[bork] 11 finding(s) — details in ~/.bork/runs/20260914-144915-myproject/findings/
  1. [high/VERIFIED] huge-payload-kills-server.md
     ...
```

## How it works

```
prep (git worktree) -> triage (1 agent classifies likely bug types)
-> hunt plan (one hunter per class, --n extras round-robined)
-> parallel hunters (pi agents, full tool access) -> findings harvest + dedup + report
```

The orchestrator has **no LLM in it** — it's a thin Python supervisor doing
git plumbing, prompt assembly, process spawning, and report generation. All
the intelligence lives in the spawned [pi](https://github.com/earendil-works/pi)
agents, who get full tool access (bash, read, edit) inside a contained
worktree: they figure out how to build the target themselves, write attack
probes, execute them, and file reports.

Two principles drive the design:

- **Honest findings.** A finding is `verified: yes` only if the hunter
  *executed* something that crashed, hung, or produced wrong output.
  Reasoned-only bugs are marked as suspected.
- **The ledger.** Every run's findings are recorded per-repo
  (`~/.bork/ledger/`) and fed back into future runs: triage is told not to
  re-propose known classes, hunters are told to find *new* breakage or
  *escalate* known findings — or, if a known bug looks fixed, to verify the
  fix (`severity: info`). Repeated runs on the same repo spiral outward
  instead of treading water.

## Install

```bash
git clone https://github.com/WillChangeThisLater/bork && cd bork
ln -s $PWD/bin/bork ~/.local/bin/bork
```

**Note:** `bork` collides with the bash/zsh builtin of the same name, which
shadows PATH lookups. If `bork -h` does nothing, add to your `~/.zshrc`:

```zsh
bork() { "$HOME/.local/bin/bork" "$@"; }
```

Requires [pi](https://github.com/earendil-works/pi) (any configured model
provider) and git. State lives in `~/.bork/` — worktrees, runs, findings,
ledger — nothing is written into the target repo.

## Usage

```bash
bork                            # cwd repo, HEAD working tree
bork ~/repos/somerepo           # explicit repo
bork --last-commit              # attack what the last commit changed
bork --diff main..HEAD          # attack a range (worktree at the range end)
bork --commit <sha>             # attack the repo at a commit (own worktree)

bork "focus on the streaming parser, try malformed inputs"   # prompt steering
bork --n 2                      # few hunters: triage targets the most pressing classes
bork --n 100                    # swarm: up to 12 classes, extras round-robin generic briefs
bork --classes 8                # decouple class count from hunter count
bork --fresh                    # ignore the known-findings ledger
bork --ledger                   # print what's already been surfaced
bork --model 'a,b'              # round-robin models across hunters

bork --report <run-id>          # re-show a run's findings
bork --list                     # list runs
```

Findings land in `~/.bork/runs/<run-id>/findings/*.md` with severity,
verified status, exact repro commands, and a suggested fix. Exit code `1`
means something broke; `0` means the repo held up (this round).

## Findings format

Each finding is a markdown file:

```markdown
severity: high
verified: yes
repro: ./jqllm < 2mb-item.json   # exact commands that demonstrate the bug
notes: what breaks, why, and a suggested fix
```

Dedup runs on repro signature, so swarms don't re-report the same bug
thirty times.

## Status

Early and experimental, but already field-tested: it found a
context-overflow path that killed a local LLM server, silent data-loss
paths in an LLM-powered CLI, a dead-code hold-to-talk deadlock in a TUI,
and a validation layer that fabricated schema-conformant output out of
`null` — in projects written by the authors. Real repos next.
