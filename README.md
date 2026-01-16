# Ruby Skills

Claude Code skills for Ruby development.

> [!NOTE]
> This plugin is for exploration purposes. My goal is to propose an official Ruby plugin under the `ruby/` organization if some
> of the skills from this plugin are proven helpful and effective.

## Installation

### Claude Code

```bash
/plugin install ruby-skills@github:st0012/ruby-skills
```

### Verify Installation

After installation, Claude will automatically use these skills when working with Ruby projects.

### Automatic Ruby Project Detection

When you start a Claude Code session in a directory containing:
- `Gemfile`
- `.ruby-version`
- `.tool-versions`
- `.mise.toml`

The plugin automatically detects this and instructs Claude to use the ruby-version-manager skill before running any Ruby commands.

**No manual prompting required** - Claude will proactively run version detection.

## Included Skills

### ruby-version-manager

Detects and configures Ruby version managers for proper environment setup.

#### How It Works

```
┌─────────────────────────────────────────────────────────────────┐
│                    Session Start (Ruby project)                  │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│              SessionStart hook injects skill context             │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                 Claude runs detect.sh                            │
│  • Reads stored preference (~/.config/ruby-skills/preference.json)│
│  • Detects installed version managers                            │
│  • Finds project Ruby version (.ruby-version, Gemfile, etc.)     │
│  • Returns ACTIVATION_COMMAND                                    │
└─────────────────────────────────────────────────────────────────┘
                                │
                    ┌───────────┴───────────┐
                    │                       │
        Multiple managers?           Single/preferred manager
        No preference stored                    │
                    │                           │
                    ▼                           ▼
        ┌───────────────────┐     ┌─────────────────────────────┐
        │ Ask user which    │     │ Use ACTIVATION_COMMAND      │
        │ manager to use    │     │ Chain with Ruby commands:   │
        │ Store preference  │     │ ACTIVATION && bundle exec...│
        └───────────────────┘     └─────────────────────────────┘
```

#### Why Activation Must Be Chained

Claude Code's Bash tool runs each command in a **non-persistent shell**. Environment changes do NOT persist between commands.

```bash
# WRONG - environment lost between commands:
source /usr/local/share/chruby/chruby.sh && chruby ruby-4.0.0
bundle install   # ← Uses wrong Ruby! Environment was reset.

# CORRECT - chain in single command:
source /usr/local/share/chruby/chruby.sh && chruby ruby-4.0.0 && bundle install
```

This is a Claude Code platform behavior, not a limitation of this plugin.

#### Scripts

The skill includes these scripts in `skills/ruby-version-manager/`:

| Script | Purpose |
|--------|---------|
| `detect.sh` | Main detection script - run this before Ruby commands |
| `detect-all-managers.sh` | Shared detection logic (sourced by detect.sh, also runs standalone) |
| `set-preference.sh` | Stores your preferred manager |

**Supported version managers:**

- chruby
- rbenv
- rvm
- asdf
- mise
- rv
- shadowenv

**Features:**

- Automatically detects installed version manager
- Finds project Ruby version from `.ruby-version`, `.tool-versions`, or `Gemfile`
- Provides correct activation commands for each manager
- Handles edge cases (missing versions, multiple managers, etc.)
- Asks for preferred manager when multiple are installed
- Stores preference in `~/.config/ruby-skills/`

**Prior Art:**

The version manager detection logic is based on [Ruby LSP's VS Code extension](https://github.com/Shopify/ruby-lsp/tree/main/vscode) by Shopify.

## Contributing

Any feedback, use cases, issue reports, and adjustments are all welcome.

## License

MIT License - see [LICENSE](LICENSE) for details.
