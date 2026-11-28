# kaizen: harness design

Date: 2026-11-28. Status: approved by Raph on 2026-11-28.

kaizen (Japanese: continuous improvement in small steps) is a configuration-layer harness for Claude Code: one plugin
in the `rlemaitre/claude-plugins` marketplace that sets how Claude works with Raph, whatever the task (create, fix,
review, maintain, write, explore). It replaces Superpowers, ECC's rules and agents, and several of Raph's own plugins.

## 1. Intent

- Raph wants one way of working that adapts to the task at hand, instead of a stack of third-party plugins whose rules
  overlap.
- He builds it himself, from scratch, to learn how this layer works. Replacing Superpowers rather than layering on top
  of it is a deliberate choice: learning is a goal, not a side effect.
- Ideas come from Superpowers, ECC, Ponytail, pstack (poteto) and the plugins and skills Raph uses today (section 10).
  They are ported and adapted, never installed as dependencies.

## 2. Success, non-goals, anti-goals

**Success** (Raph's words): he is not fighting the harness, and it helps him produce quality work efficiently.

**Anti-goals.** The harness fails, even if it technically runs, when it:

1. asks too many questions;
2. forces steps that do not fit the task;
3. needs correcting along the way.

**Non-goals (out of scope for now):**

- Configurable tools. Raph is the only user; tools are named concretely.
- A runtime orchestrator, a database, a reaction engine, multi-provider support, Windows or Linux support.
- Cost budgets with automatic shutoff.
- Publishing the harness for other users.

## 3. Constraints

- **Two Macs, two plans.** Personal Mac (`athena`) on a Pro plan; work Mac (`nabla-mac-raphael`) in an Enterprise
  organization. Everything must work on both. A feature that only works on the Pro plan does not count as working.
- **Enterprise org.** Claude Code's built-in security plugin skips `prompt.compose` hooks in Team and Enterprise
  organizations (recorded in `plugins/kitty-image/NOTICE.md`). The harness never relies on `prompt.compose`. No local
  `managed-settings.json` exists on the work Mac; console-pushed settings are unverified (see section 11, step 1).
- **Pro plan limits.** Agents, reviewers and parallel runs consume the allowance. The harness scales their number to
  the size of the change and runs narrow roles on cheaper models (`haiku`, `sonnet`).
- **Work data stays on the work Mac.** Nothing from work (memory content, review findings, rules learned from work
  PRs, tasks) reaches the public repo. Rules learned from a work project live in that project's own repo.
- **Public repo.** No secrets, tokens or private data in the harness.
- **Mods need `CLAUDE_CODE_ENABLE_FUNCTION_HOOKS=1`.** It is set in the dotfiles' Claude settings seed
  (`home/dot_claude/create_private_settings.json`); the work Mac must have it too.
- **Mod API is early access.** It changes between Claude Code releases. The harness type-checks against the generated
  types and runs `claude plugin validate` in its tests.
- **Raph's global rules apply:** simplicity first, all English, Markdown wrapped at 120 columns, conventional commits,
  stage files by path, never push or force-push without asking.

## 4. Core behavior (all task types)

### 4.1 Routing

- **Explicit:** Raph names the type (a slash command such as `/fix`, or words such as "this is a review").
- **Implicit:** the harness reads the request, proposes a type and the workflow it would follow, and waits for Raph's
  OK before starting.
- **Switching:** when a task turns out to be another type (a fix that needs a redesign), the harness proposes the
  switch. It never switches silently.
- **When it fires:** only when a request looks like a whole task (build, fix, review, a chore, a document, an idea to
  explore). Questions and one-line edits go straight through, with no proposal. (Raph's decision.)
- **Sizing:** the proposed workflow is the smallest that fits. A one-line fix skips design and planning. Raph can add
  steps back.

### 4.2 Never assume, ask efficiently

1. Facts the harness can look up (code, project files, docs, memory) it looks up. They never become a question.
2. Decisions and real unknowns it asks about. It does not guess what Raph wants.
3. Questions are batched: one message at the start of a phase, not one at a time during the work. Each question
   carries the harness's recommendation, so "yes" is a full answer.
4. It never asks the same thing twice: answers are recorded, and a recurring answer becomes a rule proposal (4.6).

### 4.3 Communication

The harness ports the rules of the `i-have-adhd` plugin (MIT, by Ayoub Ghriss; a NOTICE credits it) and the plugin is
uninstalled. (Raph's decision.) Replies follow its shape: the next action first, numbered steps, one concrete next
action at the end, state restated every turn, specific time estimates, no preamble, recap or closing pleasantries, lists
capped at five visible items.

### 4.4 Phases, gates, ready and done

Every workflow is a sequence of phases. A phase starts when its definition of ready holds and ends when its definition
of done holds. Definitions live at three levels; each adds to the one above and never repeats it:

| Level | Holds | Where |
|---|---|---|
| Harness | generic defaults per phase (a plan is ready when each task has success criteria; code is done when tests pass and the review is clean) | the harness |
| Repo | additions and overrides (`mise run check` passes; deployed to staging) | a file at the repo root |
| Package (monorepo) | additions for one package or subsystem | the same file in that directory |
| Task | its own acceptance criteria | the plan |

kaizen reads the nearest project file up the tree, as Claude Code reads `CLAUDE.md`: each level adds to its parent.
Without a project file, harness defaults apply. The same file names the issue tracker and what "deploy" means.

### 4.5 Enforcement ladder

Anything that can be enforced automatically is. Preferred order: types, linting, tests, agent rules, documentation.
When the harness finds a problem (in a review, a fix, a correction), it also asks which is the cheapest level that
would have caught it, and proposes the rule there.

### 4.6 Learning loop

1. A comment repeats (given or received in reviews), or Raph corrects the harness a second time on the same thing.
2. The harness proposes a rule, placed at the cheapest level of the ladder.
3. Raph approves or rejects it. The harness never adds a rule on its own.

Rules learned from a work project go to that project's repo.

To count repeats across sessions, each comment or correction is recorded in MemPalace on the Mac where it happened, in
the project's wing. Both palaces are local, so work records stay on the work Mac. No new store. (Builder's call.)

### 4.7 Context and token cost

- The harness shows what the current task costs (tokens, context used, agent time), using the mod API's session
  measures.
- It proposes savings, chiefly by writing reusable tools: when the same manual sequence repeats, or a step reads bulky
  output to extract a little, it proposes a script or CLI that does it in one call (pstack's "Build the Lever").
- Bulk reading goes to subagents; the main conversation keeps summaries.
- The number of reviewers and agents scales to the size of the change (section 3).

### 4.8 Simplicity

Before writing code, the harness takes the first option that fully works (from Ponytail's ladder):

1. Does it need to exist?
2. Is it already in the codebase?
3. The standard library, or a platform feature?
4. An installed dependency?
5. One line?
6. Only then, the minimum code that works.

Never cut: validation at trust boundaries, error handling that prevents data loss, security, accessibility, anything
Raph asked for. Each reply that changed code ends with what was skipped or not checked, and any risk.

### 4.9 Team and project rules (Raph's decisions)

1. **Discover.** In a repo, kaizen knows what the repo ships for agents: `CLAUDE.md`, `AGENTS.md`, `.claude/skills/`,
   `.claude/rules/`, `.claude/agents/`, the plugins its `.claude/settings.json` enables, its linters and review rules.
   Claude Code loads most of these itself; kaizen uses them, it does not reload them.
2. **Prefer the repo's own.** Where the repo has its own version of something kaizen does (a PR template, a review
   checklist, a release procedure, a coding standard), the repo's is used and kaizen's skipped.
3. **Conflicts:** a team rule that contradicts a kaizen rule wins in its repo. kaizen says so in one line, the first
   time it matters, and records it so it does not come back.
4. **Never overridden:** Raph's safety guards (section 8) and "work data stays on the work Mac". A team rule can add
   constraints on top of them, never remove them.
5. **Learning:** a rule learned in a team repo is proposed to that repo, through its usual review, never to kaizen.

### 4.10 Large repos and monorepos

kaizen works with Claude Code's own mechanisms for large codebases
(<https://code.claude.com/docs/en/large-codebases>), never around them.

1. **Lazy discovery.** Team rules (4.9) are read for the current package and the paths a task touches, never by
   scanning the tree at session start.
2. **Small footprint.** Claude Code cuts skill descriptions when many skills are loaded, and a monorepo can bring
   hundreds. kaizen keeps few skills, with short descriptions that lead with trigger words, and short always-on rules.
3. **Nested project file** (4.4): the nearest one up the tree applies, each level adding to its parent.
4. **Sparse worktrees.** Worktrees (absorbed `worktree-sessions`) go through Claude Code's worktrees and respect the
   repo's `worktree.sparsePaths` and `symlinkDirectories`.
5. **No full-tree scans.** The session-changes view (6.3) comes from the session's own edits plus `git diff` limited to
   touched paths. Start-up checks never walk the tree. Code search goes through LSP first; bulk reading goes to
   subagents.
6. **Plans in files.** Claude Code re-injects a plan file after a compaction, so a cross-package change keeps its plan.
7. **Checks where the change is:** tests and linters run in the package that changed, not across the monorepo.
8. **Learned rules at the right level:** a package's `CLAUDE.md` for one package, a `.claude/rules/` file with
   `paths:` for scattered paths, the root for everything.

## 5. Workflows

### 5.1 Create

1. **Design.** Brainstorm from several points of view (design, product, user, engineering), keeping only those that
   apply.
2. **Plan.** Split the work into increments where possible. Raph approves the plan.
3. **Implement, task by task.** A short implementation plan for a non-trivial task, then TDD under the coding rules
   of the language and project.
4. **Review.** Automatic, plus human review when others work on the project (5.3).
5. **Deploy.** Defined per project (merge a PR, publish a package, `chezmoi apply`).

### 5.2 Fix

1. **Reproduce** the problem, with a failing test on a code project. Inputs can come from Sentry or GCP logs.
2. **Find the root cause** with Raph.
3. **Choose:** the harness lays out a workaround and a proper fix, weighed by urgency and complexity; Raph picks. A
   workaround leaves a tracked shortcut behind (Ponytail's `shortcut: <limit>, <when to upgrade>` comment, or a task).
4. **Implement** the choice, then continue with Create's implement, review and deploy phases. The failing test from
   step 1 is the success criterion. The failing test lands before the fix in git history.

### 5.3 Review (code or documents)

1. **Context first:** why the change exists, what changed, where to start reading, what risks it brings.
2. **Human review** focuses on the high level: architecture, design, domain model.
3. **Agent review** covers the low level, in parallel, from several points of view. It reads the code the change
   touches, not only the diff. Each finding states what the code does, what goes wrong, the fix, and the cost of
   skipping it.
4. **Agent findings stay hidden until Raph asks for them**, so they do not bias his review. Raph decides.
5. **Self-review exception:** when Raph reviews his own work (before a PR, or content he wrote), agent findings come
   immediately.

### 5.4 Maintain

Chores: version upgrades, dependency bumps, adding a tool to the Macs.

1. Follow the project's recipe for that chore, if it has one (for dotfiles: `docs/maintenance.md`).
2. Change the smallest thing that does the job.
3. Run the project's checks.
4. Show the diff for review.

No design or planning phase. A chore without a recipe gets one written afterwards. A risky upgrade (a major version with
breaking changes) switches to Create.

### 5.5 Write (docs, articles)

1. **Brainstorm** the content.
2. **Outline**, approved by Raph.
3. **Write**: Raph, the agent or both, always under the writing rules (starting from
   `~/Developer/workspace/02_context/writing-style.md`).
4. **Review** once Raph says a version is ready: automatic, plus human reviewers when there are any. When Raph wrote it,
   agent findings come immediately (5.3, step 5).
5. **Deploy:** publish.

### 5.6 Explore (an idea to dig into)

For comprehension, learning, or a brain dump.

- **During:** Raph leads and the harness follows the thread. It researches, explains, and asks questions that help him
  think. It does not push toward building.
- No gates and no definition of done: it ends when Raph says so.
- **At the end,** the harness proposes one outcome and Raph picks:
  1. **another task** (fix, create, write…), with what came out of the exploration as the input to that workflow's
     first phase;
  2. **memory:** what was learned or decided goes to MemPalace;
  3. **nothing.**
- Routing proposes Explore when a request reads as "I want to understand…" or "I have an idea about…".

## 6. Tools

### 6.1 Rules

- Concrete tools, no abstraction layer: a skill says "use MemPalace", not "use the memory provider".
- CLI first, or a small script calling an API. MCP only when nothing else works. At work, MCP will often be the only
  option (internal tools, Slack): that is an accepted fallback, not a failure.
- A missing tool: the harness proposes installing it, following the dotfiles channel order (mise, Homebrew formula,
  cask, `mas`). It never skips the step silently.
- Each project says which issue tracker it uses; the default is GitHub Issues.
- Each workflow phase lists the tools it uses.

### 6.2 Inventory

| Tool | Used for | Machines |
|---|---|---|
| terminal-browser (its mod, `$.browser`), kitty-image | showing documents, diffs, PRs, issues, images, diagrams (6.3) | both |
| MemPalace | memory of what happened or was decided | both |
| Context7 | library documentation | both |
| LSP plugins | code navigation and diagnostics | both |
| git, `gh`, worktrunk | code, PRs, worktrees | both |
| GitHub Issues | issues, personal projects | both |
| Linear | issues and task input: the work workspace at work, a free-plan personal workspace here | both |
| Slack | task input | work |
| Gmail, Google Calendar | task input, through an MCP connector on each Mac (the work account at work, the personal account here); the harness bundles no mail or calendar access | both |
| Sentry | fix input | work |
| GCP (`gcloud`) | fix input (logs), deploy | work |
| internal tools (MCP) | depends on the tool | work |

### 6.3 Display

Everything Raph reads goes inside Claude Code where possible.

- **Engine:** the terminal-browser plugin's mod adds `$.browser.open({ url })`, which opens a page in a browser pane
  inside Claude Code. The harness lists `terminal-browser` under `dependencies` in its `plugin.json` and calls it. The
  terminal-browser CLI split is the fallback where the mod is not loaded, then the default browser where the terminal
  cannot draw (the desktop app).
- **Documents** (plans, specs, reports): the absorbed md-show renders Markdown to one HTML page (pandoc, Mermaid to
  SVG) and opens it with `$.browser.open`, not in a new terminal pane.
- **Session changes:** a view of the files the session changed and their diffs. It is fed by the `tool.call` results of
  edits and writes, plus `git diff` for changes made through shell commands.
- **PRs and issues:** GitHub PRs and issues, and Linear issues, shown inside Claude Code through `$.browser.open` on
  their URL. Builder's call, to verify in step 1 of section 11: terminal-browser keeps its own browser profile, so
  private repos and the Linear workspace may need a one-time sign-in there. If that does not work, the harness renders
  them from CLI data (`gh pr view --json`, Linear's API) into a local page instead.
- **Images and diagrams:** kitty-image, as today.

### 6.4 Memory

One design, the one in Raph's global `CLAUDE.md`:

- MemPalace: what happened or was decided (decisions, project facts, people, past sessions).
- Auto memory: how Claude should act (preferences, corrections, workflow steps).

No third store. People, acronyms and project names from the current productivity hot cache move into MemPalace as
knowledge-graph entities.

## 7. Tasks feature

Built from scratch inside the harness; it replaces the productivity plugin's task part.

- **Cross-project:** one task list per Mac, whatever the working directory.
- **Inputs:** GitHub Issues, Linear, Slack, Gmail, Google Calendar, through the tools in 6.1's order. From messages
  and meetings, the harness proposes tasks; Raph accepts them. It never adds a task on its own.
- **Dashboard:** a mod pane beside the chat, grouped by project, with a way to mark a task done.
- **Workflows:** starting a task that comes from an issue launches the matching workflow in its own worktree (as
  `worktree-sessions:issue` does today).

## 8. How it is built

- **Repo:** a new plugin in `rlemaitre/claude-plugins`, under `plugins/kaizen/`.
- **Runtime:** Claude Code mods (TypeScript hooks modules, in-process) for everything that lives inside Claude Code:
  rule injection, tool-call guards, slash commands, tools, panes, session measures. Bun + TypeScript scripts only where
  a mod cannot do the job. Startup times measured on this Mac: mod none, Bun 15 ms, bash + jq 12 ms, Node 28 ms,
  `uv run --script` 37 ms, Go and Scala Native binaries 3 to 4 ms but with a build step.
- **Rule injection:** through `prompt.context` (the first message's context blocks) or `session.append` (a hidden row
  the model reads), never `prompt.compose`. Whether each survives a compaction is to be verified; the `session.compact`
  event can re-inject after one if needed.
- **Guards:** `tool.check` hooks. They refuse (`deny`) what is never allowed: `git add -A`, `git add .`,
  `git commit -a`, staging `.idea/` changes not made in the session, force-push. They put to Raph (`ask`, the permission
  dialog) what needs his OK each time: `git push`. A deny cannot be lifted by an OK in the chat; an ask can. Advisory
  rules stay in skills. (Builder's call.)
- **Fallback if the Enterprise org blocks mods** (section 11, step 1): the same features move to classic command hooks
  in Bun + TypeScript (`SessionStart` context, `PreToolUse` guards). Panes have no command-hook equivalent, so the tasks
  dashboard and the cost display become slash commands that print their content. (Builder's call.)
- **Skill descriptions** say only when to use the skill, never the workflow it follows (Superpowers' description trap).
- **Skills are tested** against agent behavior: a scenario without the skill, then with it, including pressure
  scenarios (Superpowers' `writing-skills` method).
- **Fail-safe:** a hook that fails logs and lets the session continue, unless it is a deliberate guard.

### 8.1 Install, update, setup (Raph's decisions)

- **Install:** `kaizen@rlemaitre` goes into `enabledPlugins` of the dotfiles' Claude settings seed, so a new Mac gets
  it. The seed is only created on a new Mac, so each existing Mac runs `claude plugin install kaizen@rlemaitre` once
  (as for every plugin today, `docs/maintenance.md` in the dotfiles repo).
- **Update:** a change ships when `version` in `plugin.json` is bumped; each Mac runs
  `claude plugin update kaizen@rlemaitre`. At session start, the harness checks its own version and says in one line
  when a newer one exists. Marketplace auto-update is not relied on.
- **Tools are installed by the dotfiles only.** The harness never installs anything. It keeps one list of what it needs,
  with the machine each item is for and how to check it: CLIs (`gh`, `gcloud`, `sentry-cli`, pandoc…), MCP connectors
  (Gmail, Calendar, Slack), settings (`CLAUDE_CODE_ENABLE_FUNCTION_HOOKS`), sign-ins (`gh auth status`…).
- **Checks:**
  1. at session start, a cheap one: CLIs exist and the mods setting is on; anything missing is said in one line, with a
     proposal to add it to the dotfiles packages through the dotfiles recipe;
  2. deeper checks when a phase needs the tool (`gh auth status` before a review, the Sentry sign-in before a fix);
  3. `/kaizen doctor` runs every check on demand and reports what is missing on this Mac.
- **Setup:** no configuration file. `/kaizen setup`, once per Mac, runs the doctor's checks and walks Raph through what
  only he can do, one item at a time: sign-ins (`gh`, `gcloud`, `sentry-cli`, Linear), MCP connectors in claude.ai, the
  one-time sign-ins inside terminal-browser. For an interactive login it gives the command to type as `! <command>`,
  then checks again. Machine differences come from the dotfiles data sections; project differences from the project's
  own file.

## 9. What the harness absorbs, replaces, keeps

| Item | Fate |
|---|---|
| Superpowers | replaced; uninstalled once the harness covers its workflows |
| ECC content: `~/.claude/rules/common/`, `~/.claude/agents/` | replaced; content that conflicts with the simplicity rule (repository pattern, API envelope, blanket 80% coverage) is dropped, not ported |
| `pr-flow` | absorbed into Review and Create's review phase |
| `worktree-sessions` | absorbed into Implement, Review and the tasks feature |
| `intellij` guard | absorbed into the harness guards |
| `md-show`, `kitty-image` | absorbed as display tools (6.3); md-show opens pages through `$.browser`; `kitty-image` is MIT, from hood: its NOTICE stays and its upstream sync ends |
| `terminal-browser` | kept separate, a dependency: the harness calls its `$.browser` API |
| `productivity` | not absorbed; replaced by the tasks feature (7) and the memory design (6.4) |
| `office`, `slidev` | kept separate |
| `i-have-adhd` | absorbed into the communication rules (4.3); uninstalled |
| global `~/.claude/CLAUDE.md` (chezmoi) | trimmed: the harness takes over behavior, simplicity, PR workflow, review scope, LSP, memory, Markdown and documents rules; the file keeps "about me", dotfiles and the `.idea` note. Edited in the dotfiles repo. (Raph's decision.) |
| `~/.claude/rules/common/` (chezmoi) | deleted in the dotfiles repo. (Raph's decision.) |
| LSP plugins, MemPalace, worktrunk, terminal-browser, security-guidance, frontend-design, taste-skill | kept separate, used as tools |

## 10. Sources of ideas

| Source | Ideas taken |
|---|---|
| Superpowers | brainstorm then plan then implement; TDD; verification before completion; excuse-and-reality tables; skill pressure tests; description trap; re-injection after compaction |
| ECC | agents with limited tools (read-only reviewers); a reviewer per language; fail-safe hooks; compaction timing |
| pstack (poteto) | a router to per-type playbooks; named principles as skills, cited with the decision they changed; bug fix: reproduce, binary-search the cause, failing repro before the fix; `arena` and `interrogate` for several points of view; "Encode Lessons in Structure"; "Build the Lever" |
| Ponytail | the simplicity ladder and "never cut" list; `shortcut:` comments and a debt ledger; review that reads the touched code, finding format; reply ends with what was skipped; the cost band as a mod |
| The gist (harness comparison) | configuration-layer vs runtime harness; layered advisory and enforced gates; fail-closed CI |
| Raph's plugins | `pr-flow` review guide, pre-PR gate, babysitter, review-feedback loop; `worktree-sessions`; dotfiles recipes |

### 10.1 Licensing (Raph's decisions)

- Every source above is MIT (Superpowers, ECC, Ponytail, pstack, i-have-adhd, kitty-image, terminal-browser). The
  productivity plugin (Apache-2.0) is not a source: the tasks feature is built from scratch.
- Ideas rewritten in kaizen's own words carry no obligation; the README credits the sources.
- A file that copies wording from a source says so, and kaizen's `NOTICE.md` keeps that source's copyright and
  permission notice (as `plugins/kitty-image/NOTICE.md` does today).
- The `claude-plugins` repo is under the MIT license (`LICENSE` at its root).
- kaizen is developed on Raph's personal Mac, on his own time.

## 11. Order of work (for the plan)

1. **Skeleton first, on both Macs:** an empty mod that injects one rule and shows it loaded. Install it on the work
   Mac before building more, to confirm the Enterprise org allows it.
2. Then the core behavior (section 4), then one workflow end to end (Fix is the smallest), then the others.
3. Superpowers and the absorbed plugins stay installed until the harness covers what they did; each is removed in its
   own step.

## 12. Left to the builder

- The file layout inside the plugin, and how skills, mods and scripts split.
- Storage format of the tasks list (a plain Markdown file per Mac is the leading option), and where it lives.
- The format of the project-level file for ready, done, tracker and deploy definitions.
- How cost measures are shown (status line, band, pane).
- Models per role, within section 3's constraints.

## 13. Open questions

None. The builder check's questions were answered by Raph (routing, global rules, `i-have-adhd`, mail and calendar)
or settled as builder's calls (guards, mods fallback, learning-loop storage).
