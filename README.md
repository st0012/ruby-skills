# Ruby Skills

Ruby's ecosystem has many version managers, a rapidly evolving typing and tooling landscape, and documentation scattered across multiple sources.

Ruby Skills helps coding agents navigate each of these — activating the correct Ruby environment, pointing to authoritative docs, and avoiding common test framework pitfalls.

## Installation

### Claude Code

**From terminal:**

```bash
claude plugin marketplace add st0012/ruby-skills
claude plugin install ruby-skills@ruby-skills
```

**From a Claude session:**

Send these as two separate messages. Do not paste them together.

```bash
/plugin marketplace add st0012/ruby-skills
```

After the marketplace is added, send:

```bash
/plugin install ruby-skills@ruby-skills
```

### Codex

**From terminal:**

```bash
codex plugin marketplace add st0012/ruby-skills
codex plugin add ruby-skills@ruby-skills
```

The Codex plugin exposes the same Ruby skills through Codex's skill loader. It does not use the Claude Code `SessionStart` hook.

## What to Expect

After installation, start an agent session in any Ruby project — no configuration needed. The relevant Ruby skills activate automatically.

### `ruby-version-manager`

Detects your version manager and project Ruby version, then activates it for every shell command. Supports chruby, rbenv, rvm, asdf, mise, rv, and shadowenv.

- Reads `.ruby-version`, `.tool-versions`, `.mise.toml`, or `Gemfile` to determine the required version
- Handles multi-manager environments — prompts you to set a preference if more than one is detected
- Offers to install missing Ruby versions
- Works around Claude Code's non-persistent shell by chaining activation with every command

See the [technical reference](plugins/ruby-skills/skills/ruby-version-manager/README.md) for detection internals.

### `ruby-resource-map`

Points Claude to authoritative documentation sources so it doesn't hallucinate APIs or rely on outdated references.

- Version-specific docs for Ruby 3.2–4.0 and master
- Core vs bundled vs default gem distinctions
- Ruby typing ecosystem: Sorbet (RBI) and RBS, including Tapioca, Spoom, Steep, and RBS inline comments
- Blocks known-bad sources (ruby-doc.org, apidock.com)

### `ruby-test-frameworks`

Divergence reference for minitest and test-unit — the two frameworks have deceptively similar APIs with critical naming differences that cause `NoMethodError` at runtime.

- Side-by-side assertion naming mismatches (`assert_raises` vs `assert_raise`, `refute_*` vs `assert_not_*`, etc.)
- CLI flag comparison for test selection (by name, line number, class, pattern)
- Lifecycle differences (`startup`/`shutdown`/`cleanup` in test-unit, `before_setup`/`after_teardown` in minitest)
- Rails-specific aliases that blur the line between the two frameworks

#### Why not RSpec?

RSpec has a distinct API (`describe`/`it`/`expect`) that doesn't overlap with minitest or test-unit. LLMs rarely confuse it with other frameworks, so a divergence reference isn't needed.

## Acknowledgements

The version manager detection logic is based on [Ruby LSP's VS Code extension](https://github.com/Shopify/ruby-lsp/tree/main/vscode) by Shopify.

## Contributing

Feedback, use cases, issue reports, and contributions are all welcome on [GitHub](https://github.com/st0012/ruby-skills).

## License

MIT License - see [LICENSE](LICENSE) for details.
