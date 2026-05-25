# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

> **Note:** This gem was originally published as `micro-attributes` (`0.1.0`) and renamed to `u-attributes` starting with `0.2.0` on 2019-07-02.

## [3.1.0] - 2026-05-25
### Added
- `Micro::Entity` — a base class that bundles the `:initialize`, `:accept`, and `:diff` features so subclasses get a hash initializer with attribute-level type checks and `#with_attribute(s)` out of the box. Pass an `Entity` subclass via `accept:` to auto-coerce a nested hash into that entity (instances pass through). Pass a block to `attribute` to define an anonymous nested `Micro::Entity` inline. `Micro::Entity::Strict` layers `Micro::Attributes.with(initialize: :strict, accept: :strict)` so every attribute is required and any accept rejection raises (closes [#9](https://github.com/serradura/u-attributes/issues/9)). Requires `require 'micro/entity'`.
- `Micro::Attributes.with(initialize: :strict, accept: :strict)` (and the same hash form on `Micro::Attributes.without`) now honors every key. Previously, `fetch_key` returned the first matching strict variant and silently dropped the others; multi-key strict hashes are now expanded by `split_strict_hash` before lookup.

### Changed
- **Heads up — silent behavior shift for downstream consumers:** `Micro::Attributes.with(initialize: :strict, accept: :strict)` and `Micro::Attributes.without(initialize: :strict, accept: :strict)` now resolve to a different feature module than 3.0.x because the multi-key strict hash bug was fixed. Pre-3.1 `with(initialize: :strict, accept: :strict)` returned only `AcceptStrict`; post-3.1 it returns `AcceptStrict_InitializeStrict`. Pre-3.1 `without(initialize: :strict, accept: :strict)` only excluded `AcceptStrict`; post-3.1 it excludes both strict variants. Any code that relied on the silent drop will get a different feature mix on upgrade.
- **Heads up — silent behavior shift for `Features::Accept` consumers with private/protected attributes:** the `:accept` feature used to leak `private:` / `protected:` attributes into the public `#attributes` hash (a divergence from the base `Micro::Attributes` behavior). The fix aligns Accept with the base, but it changes two user-visible flows: `#with_attribute(s)` round-trips no longer carry private/protected values (they revert to defaults on the new instance), and `Diff::Changes` no longer reports changes for private/protected attributes. Code that depended on the leaked behavior will need to switch to explicit accessors or to public visibility.

### Fixed
- `attribute!` (subclass overwrite) with a `default:` did not clear the inherited `__attributes_required__` entry when the parent had `Initialize::Strict`. `Child.new({})` raised `ArgumentError: missing keyword: ...` even though the child gave the attribute a default. `__attributes_required_add` is now an add-or-remove sync (always called from `__attributes_data_to_assign`) so the required set always reflects the current options.
- `attribute!` (subclass overwrite) couldn't change an attribute's Ruby visibility back from `private`/`protected` to `public` — it updated `__attributes_data__` (and so the `#attributes` hash reflected the new visibility), but the inherited reader method retained its original Ruby visibility. `__attribute_assign` now re-applies visibility for already-defined attributes when overwriting.
- `Features::Accept` was leaking `private:` / `protected:` attributes into the public `#attributes` hash. The base `__attribute_assign` correctly gates the write on `attribute_data[3] == :public`, but the Accept override wrote unconditionally. Now matches the base behavior. (See also the `Changed` section above — this is the source of the round-trip and diff shifts.)
- `Micro::Entity`'s block-form nested attribute (`attribute :foo do ... end`) used to leak the immediate superclass's user-defined attributes into the inline nested class, and after that fix it still leaked sibling attributes added to the same class body AFTER the block ran (via Ruby's dynamic dispatch on inherited `attr_reader`s). The inline class now always inherits from a gem-provided base (`Micro::Entity` or `Micro::Entity::Strict`), preventing both leaks. Tradeoff: user-added feature includes (`KeysAsSymbol`, `ActiveModelValidations`) on intermediate classes don't propagate to inline children — define those nested entities explicitly and pass via `accept:`.
- `Micro::Entity` block-form rejection messages no longer leak the anonymous class's object address (e.g. `#<Class:0x000000012345>`). Inline classes now expose a stable `to_s` / `inspect` like `Outer(attr_name)`.

## [3.0.2] - 2026-05-24
### Added
- This `CHANGELOG.md`, covering the full history of the gem (from `micro-attributes 0.1.0` through `u-attributes 3.0.2`) following the [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/) spec.
- `changelog_uri`, `source_code_uri` and `bug_tracker_uri` entries in `spec.metadata` so RubyGems.org surfaces direct links from the gem page and tools like `bundle outdated` can deep-link to the changelog.

## [3.0.1] - 2026-05-23
### Fixed
- Widened the `kind` runtime dependency upper bound from `< 6.0` to `< 7.0` so `u-attributes 3.x` resolves against the just-released `kind 6.x` (no API change in `u-attributes`; pure dependency unlock).

## [3.0.0] - 2026-05-23
### Changed
- **BREAKING:** Bumped minimum Ruby to **2.7.0** (Ruby 2.2 – 2.6 are EOL and no longer supported).
- Modernized the CI/test runner via Appraisal (mirroring the `u-case` layout): the per-Ruby `ENV`-switched `Gemfile` and the `bin/test` + `bin/prepare_coverage` scripts were replaced with an `Appraisals` file gated on `RUBY_VERSION` (covering `activemodel` 6.0 – 8.1 + edge), and the GitHub Actions matrix was rewritten to cover Ruby 2.7 – 4.0+head with conditional Rails steps plus a no-`activemodel` baseline job.
- Switched code coverage reporting from CodeClimate to **Qlty** (badges updated in the README).
- README polish: new header/badge layout aligned with `solid-process`, refreshed Documentation/Compatibility tables (1.x dropped — long EOL), and a new Ruby × Rails support matrix.

### Added
- `Appraisals` file plus Appraisal-generated gemfiles for **Rails 8.1** and **Rails edge**.
- `bin/matrix` script and `rake matrix` task to run the full local test matrix.
- `bin/setup` script.
- README documentation for the 2.x features that had landed without docs (tracking issue #35): the **Accept** extension (`accept:` / `reject:` / `allow_nil:` / `rejection_message:` + strict mode, closes #8), attribute **visibility** options (`private:` / `protected:`, closes #10), the **`freeze:`** option (`true` / `:after_dup` / `:after_clone`, closes #33), the trailing options hash on `attributes(...)` for sharing defaults/visibility/validations across multiple attributes (closes #26), and the reader-first behavior of `extract_attributes_from` (closes #24).

### Removed
- Per-Ruby `bin/test` and `bin/prepare_coverage` scripts (superseded by Appraisal + `bin/matrix`).
- The 1.x row from the README Documentation and Compatibility tables (the documentation-version table still links to the older docs for anyone needing them).

### Security
- Hardened the GitHub Actions workflow: least-privilege `contents: read` permissions on the test job and `persist-credentials: false` on `actions/checkout`.

### Fixed
- Ruby 3.4+/4.0 test compatibility: switched `MiniTest::Test` to `Minitest::Test`, made the `private`/`protected` method-error assertion quote-agnostic (Ruby 3.4 changed the quoting), and derived the `Hash#inspect`-based expected string at runtime (Ruby 3.4 changed the format).
- Pre-require `logger`/`stringio` in the test helper so old Rails (`activemodel` 6.0/7.0) loads on Ruby 3+ (neither is auto-loaded any more).
- Make the baseline Gemfile work on Ruby 4.0 by declaring `logger` and `stringio` explicitly (Ruby 4.0 prunes those default gems) and disable `error_highlight`'s source-snippet annotation in the test helper so the lib's exact error-message assertions stay stable on Ruby 3.1+.

## [2.8.0] - 2021-08-24
### Added
- Allow the `default:` option to receive a callable via `&:to_proc` (e.g. `default: :upcase.to_proc`).
- Pass the raw input as the second argument to `default:` procs, so a default can react to the value being assigned.

### Changed
- Migrate CI from Travis to GitHub Actions.

### Fixed
- Fix the `Kind::Error` raise path so the right exception class/message is surfaced when an invalid value reaches the attribute.
- Fix `bin/test`.

## [2.7.0] - 2021-02-22
### Changed
- Bump the `kind` runtime dependency to `>= 4.0, < 6.0`.

## [2.6.0] - 2020-09-22
### Added
- `freeze:` attribute option (`true` / `:after_dup` / `:after_clone`) to freeze attribute values automatically (issue #33).
- `private:` and `protected:` attribute options to control the visibility of the generated reader (issue #10).

### Fixed
- Preserve the `freeze:` / `private:` / `protected:` options when attributes are inherited.

## [2.5.0] - 2020-09-21
### Added
- **Accept** extension (`Micro::Attributes.with(:accept)`, issue #8): the `accept:` / `reject:` attribute options validate a value at assignment time and can use a `Class` (kind-of check), a predicate `Symbol` (sent to the value), or a callable. The `allow_nil:` option opts out of validation when `nil`, `rejection_message:` customizes the error message (a callable can return a per-value message), and the new strict variant raises immediately when validation fails.
- Make the Accept and `ActiveModel::Validations` extensions interoperate.

## [2.4.0] - 2020-09-11
### Added
- `Micro::Attributes.with(:keys_as_symbol)` extension to expose attribute keys as symbols.
- Allow declaring `keys_as` as a symbol.

### Changed
- The Diff extension now uses the shared attribute-access helper (consistent string/symbol handling with the rest of the library).
- Exclude the `assets/` directory from the packaged gem.

## [2.3.0] - 2020-09-06
### Added
- Options for slicing attribute data (extends the `#attributes(*names)` API introduced in 1.2.0 with the `with:` / `without:` selectors).
- `Micro::Attributes::Utils::Hashes.symbolize_keys`.

## [2.2.0] - 2020-09-02
### Added
- `attributes(...)` (plural) accepts a trailing options hash, so multiple attributes can share the same options in a single declaration (issue #26).

### Changed
- Prefer reader methods over hash accessors inside `#extract_attributes_from` (issue #24).
- Only accept `Proc` objects (not arbitrary callables) where a callable was previously allowed.

## [2.1.1] - 2020-08-28
### Fixed
- Fix the `activemodel_validations` extension.

## [2.1.0] - 2020-08-22
### Added
- Public `#defined_attributes` exposing the attribute schema of an instance.
- `Micro::Attributes::Utils::HashAccess` so the library can access hashes with either string or symbol keys.
- `required: true` attribute option that fails initialization when the attribute is missing.

### Changed
- Performance: small refactor of `Features::Initialize::Strict`.

## [2.0.1] - 2020-08-21
### Fixed
- Fix attribute assignment when the value is `false` (was being treated as missing).

### Changed
- Update gemspec summary and description.

## [2.0.0] - 2020-08-20
Major rewrite consolidating the redesign of the macro API and the features layer.

### Changed
- **BREAKING:** Default values are now declared via the `default:` keyword (e.g. `attribute :name, default: 'foo'`) instead of a positional argument. Defaults can be callables, in which case they're invoked at assignment time.
- **BREAKING:** Multiple-attribute declarations (`attributes(...)`) raise when an argument is not a `String`/`Symbol`, and a `Hash` argument is no longer allowed in the macro list.
- **BREAKING:** Renamed `Features::StrictInitialize` to `Features::Initialize::Strict`; the strict initializer is now an option of the `:initialize` feature rather than a standalone feature.
- **BREAKING:** Bumped the `kind` runtime dependency to `>= 3.0, < 5.0` (was `~> 1.0`); the strict-type checks now go through the new `kind` API.
- Switched the public API surface to single-quoted strings throughout; the gemspec `required_ruby_version` was bumped to `>= 2.2.0`.
- `Micro::Attributes.with` / `.without` were refactored, and `bundler` was added as a runtime dependency (later removed).

### Added
- `Micro::Attributes.with_all_features` shortcut.
- New `Micro::Attributes::Diff` namespace (extracted from the Diff feature so the diff API can be used outside the extension).
- `Micro::Attributes::Utils` replacing the old `Micro::Attributes::Hash` / `AttributesUtils` modules.
- Attribute options when the `ActiveModel::Validations` extension is enabled (validation directives can be declared inline on the attribute).
- Ruby 2.7 in the test matrix.

### Removed
- **BREAKING:** The `attributes!` method.
- The internal `Micro::Attributes::Hash` / `AttributesUtils` modules (superseded by `Micro::Attributes::Utils`).

## [1.2.0] - 2019-08-08
### Added
- `#attributes(*names)` accepts a list of attribute names and returns just that slice of the data.

## [1.1.1] - 2019-08-05
### Fixed
- Fix feature loading when all the `:initialize` options are used together.

## [1.1.0] - 2019-08-04
### Added
- `Micro::Attributes.without(...)` as the complement of `.with(...)`, returning the module that mixes in every feature *except* the listed ones.
- `Micro::Attributes.features()` (called without arguments) returns a module with all features wired in.

### Changed
- Deduplicate the StrictInitialize combination paths and remove the `included` hook from the strict initializer.
- Internal refactor to reduce cognitive complexity of the features module.

## [1.0.1] - 2019-07-31
### Changed
- Ignore duplicated feature options passed to `Micro::Attributes.with(...)`.

## [1.0.0] - 2019-07-29
First stable release.

### Added
- `Micro::Attributes.feature()` (singular) returning a single feature module.
- New **strict initializer** feature: `Micro::Attributes.with(:strict_initialize)` forbids missing keywords when constructing an object.
- `Micro::Attributes::Features.options()` utility helper.

### Changed
- Refactor `Micro::Attributes#attributes=`.

### Fixed
- Adjust the strict-initialize error-message assertion for Ruby < 2.3.

## [0.14.0] - 2019-07-26
### Added
- `Micro::Attributes.feature()` (singular) accessor.

### Changed
- README table of contents.

## [0.13.0] - 2019-07-10
### Added
- `Micro::Attributes::Diff` now returns a `from`/`to` pair for every entry in `Diff#differences`.
- New namespace grouping the "all-features" combinations.

### Changed
- Use frozen string literal constants throughout the library.

## [0.12.0] - 2019-07-10
### Changed
- `Micro::Attributes.features()` returns all features when invoked without arguments.

## [0.11.0] - 2019-07-10
### Added
- New **`ActiveModel::Validations`** feature (`Micro::Attributes.with(:activemodel_validations)`); CI matrix expanded to run against multiple `activemodel` versions.

### Removed
- `minitest` as a development dependency (now picked up transitively).

## [0.10.0] - 2019-07-09
### Added
- `Micro::Attributes.features()` entry point and the `Features` namespace.
- New **Diff** mixin (`Micro::Attributes::Differ`) exposing the differences between two instances; requires both sides to be of the same object type.

### Changed
- Renamed `ToInitialize` / `Differ` and moved them under the `Features` namespace; `ToInitialize` is now a public constant.
- Optimize `Micro::Attributes#attributes`.

## [0.9.0] - 2019-07-07
### Changed
- **BREAKING:** Changed the arity/behavior of the `.attribute` and `.attribute!` macros (they no longer accept the old positional-default form — defaults move to the next release's `default:` keyword path).
- Refactor `Micro::Attributes` / `Micro::Attributes::Macros`.

## [0.8.0] - 2019-07-07
### Added
- New instance methods `#attribute()` and `#attribute!()` to read/override a single attribute on an instance.
- `Micro::Attributes.to_initialize()` now mixes in via a module instead of `class_eval` strings.

### Changed
- Forbid access to internal constants from outside the library.
- **Gem renamed from `micro-attributes` to `u-attributes`** (gemspec file renamed; README and Gemfile updated to match).

## [0.7.0] - 2019-07-07
### Changed
- Restrict the macros that redefine attributes (`.attribute!` / `.attributes!`) to subclasses only.
- Refactor `Micro::Attributes#attributes`.

## [0.6.1] - 2019-07-05
### Fixed
- Fix new-attribute definition when using the `.attribute(s)!` macros.

## [0.6.0] - 2019-07-05
### Added
- `.attribute!` / `.attributes!` macros for subclasses to override the default data of inherited attributes.

## [0.5.0] - 2019-07-04
### Changed
- `.attributes_data` now requires a `Hash` argument.

## [0.4.0] - 2019-07-03
### Changed
- Internal: optimize the way attribute data is fetched.

## [0.3.0] - 2019-07-03
### Added
- Validate the constructor input.

### Changed
- Pin a required Ruby version in the gemspec.
- Fix the assignment path used when building new instances via `with_attribute(s)`.

## [0.2.0] - 2019-07-02
### Added
- Gem published under the new name **`u-attributes`** (previously `micro-attributes`); the `Micro::Attributes` namespace is unchanged.

### Fixed
- Fix attribute definition with inheritance.

## [0.1.0] - 2019-07-02
### Added
- Initial release (published as `micro-attributes`).
- `Micro::Attributes` mixin with the `.attribute` / `.attributes` macros for declaring attributes on a plain Ruby object.
- Generated reader methods plus the `with_attribute` / `with_attributes` constructors that return a new instance with the updated values (no setters).

[3.1.0]: https://github.com/serradura/u-attributes/compare/v3.0.2...v3.1.0
[3.0.2]: https://github.com/serradura/u-attributes/compare/v3.0.1...v3.0.2
[3.0.1]: https://github.com/serradura/u-attributes/compare/v3.0.0...v3.0.1
[3.0.0]: https://github.com/serradura/u-attributes/compare/v2.8.0...v3.0.0
[2.8.0]: https://github.com/serradura/u-attributes/compare/v2.7.0...v2.8.0
[2.7.0]: https://github.com/serradura/u-attributes/compare/v2.6.0...v2.7.0
[2.6.0]: https://github.com/serradura/u-attributes/compare/v2.5.0...v2.6.0
[2.5.0]: https://github.com/serradura/u-attributes/compare/v2.4.0...v2.5.0
[2.4.0]: https://github.com/serradura/u-attributes/compare/v2.3.0...v2.4.0
[2.3.0]: https://github.com/serradura/u-attributes/compare/v2.2.0...v2.3.0
[2.2.0]: https://github.com/serradura/u-attributes/compare/v2.1.1...v2.2.0
[2.1.1]: https://github.com/serradura/u-attributes/compare/v2.1.0...v2.1.1
[2.1.0]: https://github.com/serradura/u-attributes/compare/v2.0.1...v2.1.0
[2.0.1]: https://github.com/serradura/u-attributes/compare/v2.0.0...v2.0.1
[2.0.0]: https://github.com/serradura/u-attributes/compare/v1.2.0...v2.0.0
[1.2.0]: https://github.com/serradura/u-attributes/compare/v1.1.1...v1.2.0
[1.1.1]: https://github.com/serradura/u-attributes/compare/v1.1.0...v1.1.1
[1.1.0]: https://github.com/serradura/u-attributes/compare/v1.0.1...v1.1.0
[1.0.1]: https://github.com/serradura/u-attributes/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/serradura/u-attributes/compare/v0.14.0...v1.0.0
[0.14.0]: https://github.com/serradura/u-attributes/compare/v0.13.0...v0.14.0
[0.13.0]: https://github.com/serradura/u-attributes/compare/v0.12.0...v0.13.0
[0.12.0]: https://github.com/serradura/u-attributes/compare/v0.11.0...v0.12.0
[0.11.0]: https://github.com/serradura/u-attributes/compare/v0.10.0...v0.11.0
[0.10.0]: https://github.com/serradura/u-attributes/compare/v0.9.0...v0.10.0
[0.9.0]: https://github.com/serradura/u-attributes/compare/v0.8.0...v0.9.0
[0.8.0]: https://github.com/serradura/u-attributes/compare/v0.7.0...v0.8.0
[0.7.0]: https://github.com/serradura/u-attributes/compare/v0.6.1...v0.7.0
[0.6.1]: https://github.com/serradura/u-attributes/compare/v0.6.0...v0.6.1
[0.6.0]: https://github.com/serradura/u-attributes/compare/v0.5.0...v0.6.0
[0.5.0]: https://github.com/serradura/u-attributes/compare/v0.4.0...v0.5.0
[0.4.0]: https://github.com/serradura/u-attributes/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/serradura/u-attributes/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/serradura/u-attributes/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/serradura/u-attributes/releases/tag/v0.1.0
