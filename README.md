# Ruby Skills

Claude Code skills for Ruby development.

> [!NOTE]
> This plugin is for exploration purposes. My goal is to propose an official Ruby plugin under the `ruby/` organization if some
> of the skills from this plugin are proven helpful and effective.

## Installation

### Claude Code

```bash
/plugin install st0012/ruby-skills
```

### Verify Installation

After installation, Claude will automatically use these skills when working with Ruby projects.

## Included Skills

### ruby-version-manager

Detects and configures Ruby version managers for proper environment setup.

**Supported version managers:**

- rbenv
- chruby
- asdf
- mise
- rvm
- rv
- shadowenv

**Features:**

- Automatically detects installed version manager
- Finds project Ruby version from `.ruby-version`, `.tool-versions`, or `Gemfile`
- Provides correct activation commands for each manager
- Handles edge cases (missing versions, multiple managers, etc.)

**Prior Art:**

The version manager detection logic in this skill is based on [Ruby LSP's VS Code extension](https://github.com/Shopify/ruby-lsp/tree/main/vscode) by Shopify. Ruby LSP handles version manager activation to ensure the correct Ruby environment is used when starting the language server. This skill adapts that approach for Claude Code's non-persistent shell sessions.

## Contributing

Any feedback, use cases, issue reports, and adjustments are all welcome.

## License

MIT License - see [LICENSE](LICENSE) for details.
