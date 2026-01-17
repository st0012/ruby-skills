# ruby-lsp Plugin for Claude Code

Ruby LSP integration with automatic Ruby version manager detection.

## Prerequisites

**Required:** Install the ruby-skills plugin first:

```bash
claude plugin marketplace add st0012/ruby-skills
claude plugin install ruby-skills@ruby-skills
```

## Installation

```bash
claude plugin install ruby-lsp@ruby-skills
```

## Enabling the LSP Tool

> **Important:** Claude Code's LSP Tool must be enabled for this plugin to work.

Set the environment variable before starting Claude:

```bash
ENABLE_LSP_TOOL=1 claude
```

Or add to your shell profile (~/.zshrc, ~/.bashrc):

```bash
export ENABLE_LSP_TOOL=1
```

See [Known Issues](#known-issues) for details.

## How It Works

1. **Session start:** Checks if ruby-lsp gem is installed for your project's Ruby version
2. **First LSP use:** Auto-installs ruby-lsp gem if missing (progress shown in output)
3. **Every LSP use:** Activates correct Ruby version, then runs ruby-lsp

## Available LSP Operations

Once enabled, Claude can use these LSP-powered operations:

| Operation | Description |
|-----------|-------------|
| `goToDefinition` | Find where a symbol is defined |
| `findReferences` | Find all references to a symbol |
| `hover` | Get type info and documentation |
| `documentSymbol` | List all symbols in a file |
| `workspaceSymbol` | Search symbols across the project |

## Multiple Version Managers

If you have multiple Ruby version managers installed (e.g., rbenv AND chruby), you'll see a prompt to set your preference. Run:

```bash
~/.claude/plugins/cache/*/ruby-skills/*/skills/ruby-version-manager/set-preference.sh <manager>
```

Supported managers: shadowenv, chruby, rbenv, rvm, asdf, rv, mise

## Troubleshooting

### "No LSP server available"

Make sure `ENABLE_LSP_TOOL=1` is set. See [Enabling the LSP Tool](#enabling-the-lsp-tool).

### "ruby-skills plugin not found"

Install the dependency:

```bash
claude plugin install ruby-skills@ruby-skills
```

### "Multiple version managers detected"

Set your preferred manager using the command shown in the error message, then restart Claude Code.

### LSP not responding after changing Ruby version

Restart Claude Code to re-detect the Ruby environment.

## Supported File Types

- `.rb` - Ruby files
- `.rake` - Rake task files
- `.gemspec` - Gem specifications
- `.ru` - Rack configuration
- `Rakefile` - Rake build files

## Known Issues

### LSP Tool requires environment variable

Claude Code's LSP Tool has a [known race condition](https://github.com/anthropics/claude-code/issues/14803) where the LSP Manager initializes before plugins load. The `ENABLE_LSP_TOOL=1` environment variable works around this.

**Alternative workaround:** Use the [community patch](https://github.com/Piebald-AI/claude-code-lsps):

```bash
npx tweakcc --apply
```

### LSP diagnostics only in IDE mode

Real-time diagnostics (errors/warnings as you type) are only available when running Claude Code in VS Code or Cursor. In CLI mode, Claude can use LSP operations but won't see live diagnostics.
