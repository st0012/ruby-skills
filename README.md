# Ruby Skills

Ruby's ecosystem has many version managers, a rapidly evolving typing landscape, and documentation scattered across multiple sources. These Claude Code plugins help Claude navigate each of these — activating the correct Ruby environment, pointing to authoritative docs, and providing LSP-powered code intelligence.

## Plugins

| Plugin | Purpose |
|--------|---------|
| [**ruby-skills**](#ruby-skills-plugin) | Version manager detection and authoritative resource map |
| [**ruby-lsp**](#ruby-lsp-plugin) | Ruby LSP integration for code intelligence |

## Installation

**From terminal:**

```bash
claude plugin marketplace add st0012/ruby-skills

# Install both for the full experience, or just ruby-skills for version management without LSP
claude plugin install ruby-skills@ruby-skills
claude plugin install ruby-lsp@ruby-skills
```

**From a Claude session:**

```bash
/plugin marketplace add st0012/ruby-skills
/plugin install ruby-skills@ruby-skills
/plugin install ruby-lsp@ruby-skills
```

## What to Expect

After installation, start a Claude Code session in any Ruby project. Claude will:

1. Detect your version manager (chruby, rbenv, rvm, asdf, mise, rv, or shadowenv)
2. Find your project's Ruby version from `.ruby-version`, `.tool-versions`, `.mise.toml`, or `Gemfile`
3. Automatically use the correct Ruby for all commands — no manual setup needed

If you have multiple version managers installed, Claude will ask your preference once and remember it.

The ruby-skills plugin also provides Claude with a curated map of authoritative documentation sources, including version-specific docs and a few quick references for the Ruby typing ecosystem.

### ruby-skills plugin

Provides two skills:

- **Version manager detection** — Activates the correct Ruby for your project. See the [technical reference](plugins/ruby-skills/skills/ruby-version-manager/README.md) for details on the detection logic.
- **Resource map** — Curated documentation sources and typing ecosystem references.

### ruby-lsp plugin

Builds on the ruby-skills plugin to provide [Ruby LSP](https://github.com/Shopify/ruby-lsp) integration — hover documentation, go-to-definition, and diagnostics.

> [!NOTE]
> Requires `ENABLE_LSP_TOOL=1` environment variable due to a known Claude Code issue. See [Known Issues](plugins/ruby-lsp/README.md#known-issues).

- Auto-installs the ruby-lsp gem if missing
- Supports `.rb`, `.erb`, `.rake`, `.gemspec`, `.ru`, and `Rakefile`
- See [plugins/ruby-lsp/README.md](plugins/ruby-lsp/README.md) for details

## Acknowledgements

The version manager detection logic is based on [Ruby LSP's VS Code extension](https://github.com/Shopify/ruby-lsp/tree/main/vscode) by Shopify.

## Contributing

Feedback, use cases, issue reports, and contributions are all welcome on [GitHub](https://github.com/st0012/ruby-skills).

## License

MIT License - see [LICENSE](LICENSE) for details.
