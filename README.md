# Ruby Skills

Claude Code plugins for Ruby development.

> [!NOTE]
> This is an experimental project to explore Claude Code plugins for Ruby development. If proven useful, the goal is to upstream these to the `ruby/` organization.

## Plugins

This marketplace provides two plugins:

| Plugin | Purpose |
|--------|---------|
| [**ruby-skills**](#ruby-skills-plugin) | Ruby development skills for Claude. Currently includes version manager detection, with more skills planned. |
| [**ruby-lsp**](#ruby-lsp-plugin) | Ruby LSP integration for code intelligence (hover, go-to-definition, diagnostics). |

## Installation

**From terminal:**

```bash
# Add the marketplace
claude plugin marketplace add st0012/ruby-skills

# Install the plugins
claude plugin install ruby-skills@ruby-skills
claude plugin install ruby-lsp@ruby-skills
```

**From a Claude session:**

```
/plugin marketplace add st0012/ruby-skills
/plugin install ruby-skills@ruby-skills
/plugin install ruby-lsp@ruby-skills
```

After installation, Claude will automatically use these plugins when working with Ruby projects.

## ruby-skills Plugin

Provides Ruby-specific skills that teach Claude how to work effectively in Ruby projects.

### Current Skills

#### ruby-version-manager

Detects and configures Ruby version managers for proper environment setup.

**Supported version managers:** chruby, rbenv, rvm, asdf, mise, rv, shadowenv

**Features:**

- Automatically detects installed version manager
- Finds project Ruby version from `.ruby-version`, `.tool-versions`, or `Gemfile`
- Provides correct activation commands for each manager
- Handles edge cases (missing versions, multiple managers, etc.)
- Asks for preferred manager when multiple are installed
- Stores preference in `~/.config/ruby-skills/`

**Automatic detection:** When you start a Claude Code session in a directory containing `Gemfile`, `.ruby-version`, `.tool-versions`, or `.mise.toml`, the plugin automatically instructs Claude to detect and use the correct Ruby version.

### Planned Skills

More Ruby skills are planned for this plugin. Contributions and suggestions welcome.

### How Version Manager Detection Works

```
┌───────────────────────────────────────────────────────────────────┐
│                    Session Start (Ruby project)                   │
└───────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌───────────────────────────────────────────────────────────────────┐
│               SessionStart hook injects skill context             │
└───────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌───────────────────────────────────────────────────────────────────┐
│  Claude runs detect.sh                                            │
│    • Reads stored preference (~/.config/ruby-skills/preference)   │
│    • Detects installed version managers                           │
│    • Finds project Ruby version (.ruby-version, Gemfile, etc.)    │
│    • Returns ACTIVATION_COMMAND                                   │
└───────────────────────────────────────────────────────────────────┘
                                  │
                    ┌─────────────┴─────────────┐
                    │                           │
        Multiple managers?              Single/preferred manager
        No preference stored                    │
                    │                           │
                    ▼                           ▼
        ┌───────────────────────┐   ┌───────────────────────────────┐
        │ Ask user which        │   │ Use ACTIVATION_COMMAND        │
        │ manager to use        │   │ Chain with Ruby commands:     │
        │ Store preference      │   │ ACTIVATION && bundle exec...  │
        └───────────────────────┘   └───────────────────────────────┘
```

### Why Activation Must Be Chained

Claude Code's Bash tool runs each command in a **non-persistent shell**. Environment changes do NOT persist between commands.

```bash
# WRONG - environment lost between commands:
source /usr/local/share/chruby/chruby.sh && chruby ruby-4.0.0
bundle install   # ← Uses wrong Ruby! Environment was reset.

# CORRECT - chain in single command:
source /usr/local/share/chruby/chruby.sh && chruby ruby-4.0.0 && bundle install
```

This is a Claude Code platform behavior, not a limitation of this plugin.

### Prior Art

The version manager detection logic is based on [Ruby LSP's VS Code extension](https://github.com/Shopify/ruby-lsp/tree/main/vscode) by Shopify.

## ruby-lsp Plugin

[Ruby LSP](https://github.com/Shopify/ruby-lsp) integration using Claude Code's [LSP support](https://code.claude.com/docs/en/plugins#lsp-servers).

> [!NOTE]
> Requires `ENABLE_LSP_TOOL=1` environment variable due to a known Claude Code issue. See [Known Issues](plugins/ruby-lsp/README.md#known-issues).

### How It Works

1. **Session start:** Checks if ruby-lsp gem is installed for your project's Ruby version
2. **First LSP use:** Auto-installs ruby-lsp gem if missing (progress shown in output)
3. **Every LSP use:** Activates correct Ruby version, then runs ruby-lsp

### Supported File Types

- `.rb` - Ruby files
- `.erb` - ERB templates
- `.rake` - Rake task files
- `.gemspec` - Gem specifications
- `.ru` - Rack configuration
- `Rakefile` - Rake build files

See [plugins/ruby-lsp/README.md](plugins/ruby-lsp/README.md) for detailed documentation.

## Project Structure

```
ruby-skills/                        # Marketplace
├── plugins/
│   ├── ruby-skills/                # Plugin: Ruby skills
│   │   ├── hooks/
│   │   └── skills/ruby-version-manager/
│   └── ruby-lsp/                   # Plugin: LSP integration
│       ├── hooks/
│       ├── scripts/
│       └── .lsp.json
└── .claude-plugin/marketplace.json
```

## Contributing

Feedback, use cases, issue reports, and contributions are all welcome.

## License

MIT License - see [LICENSE](LICENSE) for details.
