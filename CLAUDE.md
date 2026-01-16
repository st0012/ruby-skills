# Ruby Skills Plugin - Development Guide

## For Claude: When to Run Tests

**Run these tests automatically when:**
- You modify any `.sh` script in this plugin
- You change detection logic in `detect.sh` or `detect-all-managers.sh`
- Before committing changes to the plugin
- When debugging issues reported by the user

**Minimum verification before any commit:**
1. Run `detect.sh` and verify it outputs valid key=value pairs
2. Test that `ACTIVATION_COMMAND` actually switches Ruby versions

## Project Structure

```
ruby-skills/
├── plugin.json           # Plugin manifest
├── hooks/
│   └── session-start.sh  # Injects skill context on Ruby project detection
└── skills/
    └── ruby-version-manager/
        ├── SKILL.md              # Main skill documentation (Claude reads this)
        ├── detect.sh             # Main detection script
        ├── detect-all-managers.sh # Shared detection logic (sourced by detect.sh)
        └── set-preference.sh     # Stores user's manager preference
```

## Test Suite

### Test 1: Basic Detection

**When to run:** After any change to `detect.sh` or `detect-all-managers.sh`

```bash
cd /path/to/ruby/project
/path/to/ruby-skills/skills/ruby-version-manager/detect.sh
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
/path/to/ruby-skills/skills/ruby-version-manager/detect.sh
```

**Verify:** Output includes `NEEDS_USER_CHOICE=true` and `AVAILABLE_MANAGERS` lists all installed managers.

**Cleanup:** Restore preference if needed with `set-preference.sh`.

### Test 4: Preference Storage

**When to run:** After changes to `set-preference.sh` or preference reading logic

```bash
# Set preference
/path/to/ruby-skills/skills/ruby-version-manager/set-preference.sh <manager>

# Verify file contents
cat ~/.config/ruby-skills/preference.json

# Verify detect.sh uses the preference
/path/to/ruby-skills/skills/ruby-version-manager/detect.sh
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

## Common Issues

### chruby not detected

chruby doesn't have a `--version` flag. Detection checks:
1. `chruby.sh` at `/opt/homebrew/share/chruby/`, `/usr/local/share/chruby/`, `/usr/share/chruby/`
2. Ruby installations in `~/.rubies` or `/opt/rubies`

### Activation doesn't switch Ruby version

The `ACTIVATION_COMMAND` must use explicit `chruby <version>`, not `auto.sh`. The `auto.sh` script only triggers on `cd`, which doesn't work in Claude Code's non-persistent shell.

### Environment doesn't persist

Expected behavior. Claude Code runs each Bash command in a fresh shell. Always chain: `ACTIVATION && ruby_command`.
