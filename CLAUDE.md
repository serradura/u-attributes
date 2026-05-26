# CLAUDE.md

Notes for AI assistants working in `u-attributes`.

## Golden rule: no breaking API changes — ever

`u-attributes` is a runtime dependency of [`u-case`](https://github.com/serradura/u-case), whose own public API is frozen. **The same compromise applies here:** the public API and runtime contracts of `u-attributes` won't break. Every change must keep existing code working — both for direct users of the gem and for `u-case` (and everything that transitively depends on it).

Major version bumps are reserved for dependency-floor changes (dropping a Ruby or `activemodel` version from the supported matrix) per SemVer. They do **not** signal a behavior break.

If a task as stated would require a breaking change to honor it, stop and surface that — propose a backward-compatible path, or flag that the request can't be satisfied without violating this rule. Don't ship the break.

## How to work in this repo

### 1. Think before coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

- State assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them — don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

### 2. Simplicity first

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes,
simplify.

### 3. Surgical changes

**Touch only what you must. Clean up only your own mess.**

- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it — don't delete it.
- Remove imports/variables/functions that _your_ changes orphaned. Don't
  remove pre-existing dead code unless asked.

The test: every changed line should trace directly to the user's request.

### 4. Goal-driven execution

**Define success criteria. Loop until verified.**

Turn vague tasks into verifiable goals:

- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step work, state a brief plan with a verification check per step.

---

## What this is

`u-attributes` is a Ruby gem (originally published as `micro-attributes`) for
defining "immutable" objects: classes get attribute readers (no setters), and
mutation happens via `#with_attribute` / `#with_attributes` constructors that
return a new instance. Entry points live under `lib/micro/attributes`
(`Micro::Attributes`, the `.attribute` / `.attributes` macros, and the opt-in
features under `Micro::Attributes.with(...)` — `:initialize` (+ strict mode),
`:diff`, `:accept`, `:keys_as_symbol`, `:activemodel_validations`). It is a
runtime dependency of sibling gems like `u-case`, so behavior changes — and
especially anything that affects the public API or the supported `ruby` /
`activemodel` / `kind` matrix — are highly visible to downstream users.

## Running tests

```bash
bundle exec rake test                  # default suite, current bundle (no activemodel)
bundle exec appraisal <name> rake test # one Rails appraisal (see Appraisals)
bundle exec rake matrix                # full local matrix for the active Ruby
```

`bin/setup` re-installs and refreshes appraisals. `bin/matrix` reinstalls then
runs `rake matrix`. CI runs the matrix across the full Ruby × Rails grid plus
a no-`activemodel` baseline job. Tests are the success criterion for any
behavior change — write or update a test first, then make it pass (rule 4).

## CHANGELOG and README are part of every change

Both files are user-facing — keep them in sync with the code:

- **`CHANGELOG.md`**: follows [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/).
  Every user-visible change (new macro/option, behavior change, breaking
  change, dep bump that shifts the supported matrix, security fix) gets a
  bullet under the appropriate section (`Added` / `Changed` / `Deprecated` /
  `Removed` / `Fixed` / `Security`). Pure README/CI/internal-refactor changes
  generally don't need an entry.
- **`README.md`**: the **Documentation** table and the **Compatibility** table
  at the top reference the latest released version and its dependency bounds.
  If you change a documented API, update the README in the same commit.

## Bumping the version

1. Edit `lib/micro/attributes/version.rb` — change `Micro::Attributes::VERSION`.
   Follow [SemVer](https://semver.org/): patch for fixes, minor for additive
   user-visible changes, major for breaking changes.
2. Add a new top entry in `CHANGELOG.md` (`## [X.Y.Z] - YYYY-MM-DD`) and a
   matching compare link at the bottom (`[X.Y.Z]: …/compare/vPREV...vX.Y.Z`).
3. Update the README:
   - **Documentation** table → bump the `v3.x` (or current major) row's
     version label.
   - **Compatibility** table → if dependency bounds changed, add a new row;
     otherwise bump the existing row's version label.
4. If `Gemfile`/`u-attributes.gemspec` dependency bounds moved (currently
   `kind >= 4.0, < 7.0` and `required_ruby_version >= 2.7.0`), double-check
   the Compatibility table and `Appraisals` reflect the new bounds.

Don't tag, push, or `gem release` — humans do that.
