# Ruby Skills - Development Guide

## For Claude: When to Run Tests

**Run these tests automatically when:**
- You modify any `.sh` script in either plugin
- You change detection logic in `detect.sh` or `detect-all-managers.sh`
- Before committing changes to either plugin
- When debugging issues reported by the user

**Minimum verification before any commit:**
1. Run `detect.sh` and verify it outputs valid key=value pairs
2. Test that `ACTIVATION_COMMAND` actually switches Ruby versions

## Project Structure

This repository is a **plugin marketplace** containing two plugins:

```
ruby-skills/                            # Marketplace root
├── .claude-plugin/
│   └── marketplace.json                # Marketplace definition
├── plugins/
│   ├── ruby-skills/                    # Plugin: version manager detection
│   │   ├── .claude-plugin/plugin.json
│   │   ├── hooks/
│   │   │   ├── hooks.json
│   │   │   └── session-start.sh
│   │   └── skills/
│   │       └── ruby-version-manager/
│   │           ├── SKILL.md
│   │           ├── detect.sh
│   │           ├── detect-all-managers.sh
│   │           └── set-preference.sh
│   └── ruby-lsp/                       # Plugin: LSP integration
│       ├── .claude-plugin/plugin.json
│       ├── .lsp.json
│       ├── hooks/
│       │   ├── hooks.json
│       │   └── check-ruby-lsp.sh
│       ├── scripts/
│       │   └── launch-ruby-lsp.sh
│       └── README.md
├── CLAUDE.md                           # This file
└── README.md                           # User documentation
```

## Test Suite

### Test 1: Basic Detection

**When to run:** After any change to `detect.sh` or `detect-all-managers.sh`

```bash
cd /path/to/ruby/project
/path/to/ruby-skills/plugins/ruby-skills/skills/ruby-version-manager/detect.sh
```

**Verify:**
- Output contains `VERSION_MANAGER=<manager>` (not empty or "none" if manager is installed)
- Output contains `ACTIVATION_COMMAND=<command>` (not empty)
- Output contains `VERSION_AVAILABLE=true` (if the Ruby version is installed)

### Test 2: Activation Command Works

**When to run:** After any change to activation logic

```bash
# Parse ACTIVATION_COMMAND from detect.sh output, then:
<ACTIVATION_COMMAND> && ruby -v
```

**Verify:** Ruby version matches `PROJECT_RUBY_VERSION`, not the system/inherited Ruby.

### Test 3: Multi-Manager Detection (if applicable)

**When to run:** After changes to manager detection logic, if user has multiple managers

```bash
# Temporarily clear preference
rm -f ~/.config/ruby-skills/preference.json

# Run detection
/path/to/ruby-skills/plugins/ruby-skills/skills/ruby-version-manager/detect.sh
```

**Verify:** Output includes `NEEDS_USER_CHOICE=true` and `AVAILABLE_MANAGERS` lists all installed managers.

**Cleanup:** Restore preference if needed with `set-preference.sh`.

### Test 4: Preference Storage

**When to run:** After changes to `set-preference.sh` or preference reading logic

```bash
# Set preference
/path/to/ruby-skills/plugins/ruby-skills/skills/ruby-version-manager/set-preference.sh <manager>

# Verify file contents
cat ~/.config/ruby-skills/preference.json

# Verify detect.sh uses the preference
/path/to/ruby-skills/plugins/ruby-skills/skills/ruby-version-manager/detect.sh
```

**Verify:** `PREFERRED_MANAGER=<manager>` appears in output.

## Manual Testing for Developers

### Full Plugin Test

After making changes, reinstall and test in a new session:

```bash
# Reinstall plugin
claude plugin uninstall ruby-skills@local-dev
claude plugin install ruby-skills@local-dev

# Start new session in a Ruby project
cd /path/to/ruby/project
claude

# Claude should automatically use the ruby-version-manager skill
```

## Files That Must Stay In Sync

**`plugins/ruby-skills/hooks/session-start.sh` and `plugins/ruby-skills/skills/ruby-version-manager/SKILL.md` contain overlapping instructions.**

The session-start hook has inline instructions about:
- Running detect.sh
- Handling NEEDS_USER_CHOICE=true
- Using ACTIVATION_COMMAND
- DO NOT list for Ruby commands

These instructions mirror content in SKILL.md. When updating either file:
1. Check if the change affects shared content
2. Update both files if needed
3. Run the full plugin test to verify behavior

## Common Issues

### chruby not detected

chruby doesn't have a `--version` flag. Detection checks:
1. `chruby.sh` at `/opt/homebrew/share/chruby/`, `/usr/local/share/chruby/`, `/usr/share/chruby/`
2. Ruby installations in `~/.rubies` or `/opt/rubies`

### Activation doesn't switch Ruby version

The `ACTIVATION_COMMAND` must use explicit `chruby <version>`, not `auto.sh`. The `auto.sh` script only triggers on `cd`, which doesn't work in Claude Code's non-persistent shell.

### Environment doesn't persist

Expected behavior. Claude Code runs each Bash command in a fresh shell. Always chain: `ACTIVATION && ruby_command`.

## ruby-lsp Plugin

### Overview

The `plugins/ruby-lsp/` directory contains a Claude Code LSP plugin that provides Ruby language server integration. It depends on the `ruby-skills` plugin for Ruby environment detection.

**Important:** Requires `ENABLE_LSP_TOOL=1` environment variable due to a known Claude Code race condition bug.

### Architecture

```
plugins/ruby-lsp/
├── .claude-plugin/
│   └── plugin.json        # Plugin manifest
├── .lsp.json              # LSP server configuration
├── hooks/
│   ├── hooks.json         # Hook configuration
│   └── check-ruby-lsp.sh  # SessionStart hook - early warnings
├── scripts/
│   └── launch-ruby-lsp.sh # LSP launcher - detection + activation + launch
└── README.md              # User documentation
```

### Key Design Decisions

1. **Separate plugin from ruby-skills**: Keeps LSP concerns isolated; users can install version manager support without LSP, or both.

2. **Standard plugin structure**: Each plugin has its own `.claude-plugin/plugin.json` and configuration files, following the pattern established by other Claude Code plugin marketplaces.

3. **Depends on ruby-skills' detect.sh**: Reuses existing detection logic rather than duplicating. The launcher script finds detect.sh from the installed ruby-skills plugin in the cache.

4. **Auto-install ruby-lsp gem**: If the gem isn't installed for the detected Ruby version, the launcher installs it automatically. Progress is logged to stderr (visible to user).

5. **SessionStart hook for early warnings**: Checks dependencies at session start so users see problems before trying to use LSP features.

6. **Explicit failure on NEEDS_USER_CHOICE**: When multiple version managers are detected without a preference, the launcher fails with clear instructions rather than guessing.

### Testing

**Automated (script-level):**
- Test detect.sh produces expected output in Ruby projects
- Test hook script handles missing ruby-skills gracefully
- Test launcher script handles NEEDS_USER_CHOICE case

**Manual (plugin-level):**
- Install both plugins from marketplace
- Ensure `ENABLE_LSP_TOOL=1` is set
- Test in Ruby project: hover, go-to-definition, diagnostics
- Test auto-install flow by uninstalling ruby-lsp gem first
- Test multiple manager scenario by removing preference

### Known Limitations

- Requires `ENABLE_LSP_TOOL=1` environment variable (Claude Code bug workaround)
- `${CLAUDE_PLUGIN_ROOT}` in `.lsp.json` is used for the launch script path
- Each Bash command runs in fresh shell, so activation must be chained with ruby-lsp launch
- Some version managers (like chruby) use undefined variables, requiring `set +u` in subshells