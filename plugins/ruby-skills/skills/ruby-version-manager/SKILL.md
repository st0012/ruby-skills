---
name: ruby-version-manager
description: Use at session start for Ruby projects (Gemfile, .ruby-version, or .tool-versions present). Detect version manager BEFORE running ruby, bundle, gem, rake, rails, rspec, or any Ruby command.
---

# Ruby Version Manager Skill

Detects and configures Ruby version managers for proper environment setup.

## When to Use

**Run detect.sh IMMEDIATELY when:**
- Starting work in a directory with `Gemfile`, `.ruby-version`, or `.tool-versions`
- Before your first Ruby command (`ruby`, `bundle`, `gem`, `rake`, `rails`, `rspec`, etc.)
- When switching between Ruby projects

**Do NOT wait** for commands to fail or user requests. Proactive detection prevents version mismatch errors.

**Always chain activation with commands:** `ACTIVATION_COMMAND && ruby_command`

## Usage

### Step 1: Run detect.sh

Run `detect.sh` from this skill's directory (path provided by session-start hook).

### Step 2: Parse Output

The script outputs key=value pairs:

```text
VERSION_MANAGER=rbenv
PROJECT_RUBY_VERSION=3.2.0
VERSION_AVAILABLE=true
ACTIVATION_COMMAND=eval "$(rbenv init -)"
```

### Step 3: Execute Ruby Commands

Chain `ACTIVATION_COMMAND` with your Ruby command:

```bash
eval "$(rbenv init -)" && bundle install
eval "$(rbenv init -)" && bundle exec rspec
```

Run detect.sh once per project session; reuse `ACTIVATION_COMMAND` for subsequent commands.

## Output Variables

| Variable | Description |
|----------|-------------|
| `VERSION_MANAGER` | Detected: shadowenv, chruby, rbenv, rvm, asdf, rv, mise, or none |
| `VERSION_MANAGER_PATH` | Installation path |
| `PROJECT_RUBY_VERSION` | Version required by project |
| `PROJECT_VERSION_SOURCE` | Source file (.ruby-version, .tool-versions, .mise.toml, Gemfile) |
| `RUBY_ENGINE` | Implementation (ruby, truffleruby, jruby) |
| `INSTALLED_RUBIES` | Comma-separated available versions |
| `VERSION_AVAILABLE` | true/false - whether requested version is installed |
| `ACTIVATION_COMMAND` | Shell command to activate the manager |
| `SYSTEM_RUBY_VERSION` | System Ruby (when VERSION_MANAGER=none) |
| `WARNING` | Environment warnings |
| `NEEDS_USER_CHOICE` | true when multiple managers detected without preference |
| `AVAILABLE_MANAGERS` | List of detected managers (when NEEDS_USER_CHOICE=true) |
| `NEEDS_VERSION_CONFIRM` | true when no version specifier found |
| `SUGGESTED_VERSION` | Latest installed Ruby (when NEEDS_VERSION_CONFIRM=true) |

## Activation Commands by Manager

| Manager | Activation Command | Notes |
|---------|-------------------|-------|
| rbenv | `eval "$(rbenv init -)"` | Or use `rbenv exec ruby ...` |
| chruby | `source .../chruby.sh && chruby <version>` | detect.sh provides full command |
| rvm | `source "$HOME/.rvm/scripts/rvm"` | Or use `~/.rvm/bin/rvm-auto-ruby` |
| asdf (v0.16+) | None | `asdf exec ruby ...` |
| asdf (<v0.16) | `source "$HOME/.asdf/asdf.sh"` | Then `asdf exec ruby ...` |
| mise | None | `mise x -- ruby ...` |
| rv | None | `rv ruby run -- ...` |
| shadowenv | None | `shadowenv exec -- ruby ...` |
| none | None | `ruby ...` (uses PATH) |

## Commands Requiring Activation

| Category | Commands |
|----------|----------|
| Core | `ruby`, `irb`, `gem`, `bundle`, `bundler` |
| Build/Task | `rake`, `rails`, `thor` |
| Testing | `rspec`, `minitest`, `cucumber` |
| Linting | `rubocop`, `standardrb`, `reek` |
| LSP/IDE | `ruby-lsp`, `solargraph`, `steep` |
| Debug | `pry`, `byebug`, `debug` |
| Gem binaries | Any executable from `gem install` or Gemfile |

## Handling Special Cases

### Multiple Version Managers (NEEDS_USER_CHOICE=true)

Ask the user which manager to use, then store preference:

```bash
/path/to/set-preference.sh chruby  # Saves to ~/.config/ruby-skills/preference.json
```

Detection priority: shadowenv > chruby > rbenv > rvm > asdf > rv > mise > none

### No Version Specifier (NEEDS_VERSION_CONFIRM=true)

Ask: "No .ruby-version found. Use Ruby [SUGGESTED_VERSION] for this session?"
If declined, show options from INSTALLED_RUBIES.

### Version Not Installed (VERSION_AVAILABLE=false)

Inform user and offer installation:

> Ruby {PROJECT_RUBY_VERSION} is not installed. Install with:
> - **rbenv:** `rbenv install {VERSION}`
> - **rvm:** `rvm install {VERSION}`
> - **asdf:** `asdf install ruby {VERSION}`
> - **mise:** `mise install ruby@{VERSION}`
> - **chruby:** `ruby-install ruby {VERSION}`

**Always ask before installing.** For chruby, check INSTALLED_RUBIES for compatible versions (same major.minor).

### Shadowenv Trust Issues

If "untrusted shadowenv program" error appears, user must run `shadowenv trust` in the project directory.

### Version Format Variations

Supported formats: `3.3.0`, `ruby-3.3.0`, `truffleruby-21.3.0`, `3.3.0-rc1`, `3.3` (matches any patch)

### CI/Docker Environments

When VERSION_MANAGER=none, use system Ruby directly.

## Troubleshooting

If Ruby commands fail after activation:
1. Re-run detect.sh to verify environment
2. Check `VERSION_AVAILABLE` - install if false
3. Verify manager installation at `VERSION_MANAGER_PATH`
4. **chruby:** Check `~/.rubies` or `/opt/rubies` for installations
5. **rvm:** Check both `~/.rvm` and `/usr/local/rvm`
