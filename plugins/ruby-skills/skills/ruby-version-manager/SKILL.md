---
name: ruby-version-manager
description: Use at session start for Ruby projects (Gemfile, .ruby-version, or .tool-versions present). Detect version manager BEFORE running ruby, bundle, gem, rake, rails, rspec, or any Ruby command.
---

# Ruby Version Manager Skill

Detects and configures Ruby version managers for proper environment setup.

## When to Use

**Run detect.sh IMMEDIATELY when:**
- Starting work in a directory with `Gemfile`, `.ruby-version`, or `.tool-versions`
- Before your first `ruby`, `bundle`, `gem`, `rake`, `rails`, or `rspec` command
- When switching between Ruby projects

**Do NOT wait for:**
- Ruby commands to fail first
- User to explicitly ask for version detection
- Problems to occur

**Proactive detection prevents version mismatch errors.**

## Manager Preference

When multiple version managers are installed, the skill asks you which one to use.

### How Preferences Work

1. **detect.sh checks for stored preference first** (in `~/.config/ruby-skills/preference.json`)
2. **If no preference and multiple managers found**, outputs `NEEDS_USER_CHOICE=true`
3. **Claude should ask the user** which manager to use
4. **Run set-preference.sh** to store the choice

### Setting Preference

```bash
# Store preference (saved to ~/.config/ruby-skills/preference.json)
/path/to/set-preference.sh chruby
```

### When Claude Sees NEEDS_USER_CHOICE=true

Ask the user:

> Multiple Ruby version managers detected: {AVAILABLE_MANAGERS}
>
> Which one would you like to use?
>
> 1. [manager1]
> 2. [manager2]
> ...

Then run `set-preference.sh` with their choice.

### When NEEDS_VERSION_CONFIRM=true

The script couldn't find a version specifier (`.ruby-version`, `.tool-versions`, etc.) but detected installed Ruby versions.

1. Check the `SUGGESTED_VERSION` value (the latest installed Ruby)
2. Ask the user: "No .ruby-version found. Use Ruby [SUGGESTED_VERSION] for this session?"
3. If user agrees:
   - Use the ACTIVATION_COMMAND with the suggested version
   - For chruby: `source /path/to/chruby.sh && chruby ruby-[VERSION]`
   - For rbenv: `eval "$(rbenv init -)" && rbenv shell [VERSION]`
   - For other managers: prepend version selection to commands
4. If user declines, ask which version they prefer from INSTALLED_RUBIES

## Critical: Non-Persistent Bash Sessions

Each bash command in Claude Code runs in a **fresh shell**. Environment variables and shell configurations do NOT persist between commands.

**You MUST chain activation with your command using `&&`:**

```bash
# WRONG - activation is lost before bundle runs:
eval "$(rbenv init -)"
bundle install

# CORRECT - single command with activation:
eval "$(rbenv init -)" && bundle install
```

This applies to ALL Ruby commands: `ruby`, `gem`, `bundle`, `rake`, `rspec`, `rails`, etc.

## Usage

### Step 1: Run Detection

Run the detection script from your Ruby project's root directory:

```bash
# Find and run detect.sh (adjust path based on your installation)
# As a plugin:
~/.claude/plugins/cache/*/ruby-skills/*/skills/ruby-version-manager/detect.sh

# As a personal skill:
~/.claude/skills/ruby-version-manager/detect.sh

# The session-start hook will tell you the exact path
```

### Step 2: Parse Output

The script outputs key=value pairs. Example output:

```
VERSION_MANAGER=rbenv
VERSION_MANAGER_PATH=/Users/you/.rbenv
PROJECT_RUBY_VERSION=3.2.0
PROJECT_VERSION_SOURCE=.ruby-version
RUBY_ENGINE=ruby
INSTALLED_RUBIES=3.1.2,3.2.0,3.3.0
VERSION_AVAILABLE=true
ACTIVATION_COMMAND=eval "$(rbenv init -)"
```

### Step 3: Execute Ruby Commands

Use the `ACTIVATION_COMMAND` value, chained with your Ruby command:

```bash
# Using the ACTIVATION_COMMAND from above:
eval "$(rbenv init -)" && bundle install
eval "$(rbenv init -)" && bundle exec rspec
eval "$(rbenv init -)" && ruby script.rb
```

### When to Run Detection

Run `detect.sh` once when:
- Starting work on a Ruby project
- Switching to a different Ruby project
- Ruby commands fail unexpectedly

You do NOT need to re-run it before every Ruby command - just reuse the `ACTIVATION_COMMAND`.

## Output Variables

| Variable | Description |
|----------|-------------|
| `VERSION_MANAGER` | Detected manager: shadowenv, chruby, rbenv, rvm, asdf, rv, mise, or none |
| `VERSION_MANAGER_PATH` | Path to the version manager installation |
| `PROJECT_RUBY_VERSION` | Ruby version required by the project |
| `PROJECT_VERSION_SOURCE` | File specifying the version (.ruby-version, .tool-versions, .mise.toml, Gemfile) |
| `RUBY_ENGINE` | Ruby implementation (ruby, truffleruby, jruby) |
| `INSTALLED_RUBIES` | Comma-separated list of available Ruby versions |
| `VERSION_AVAILABLE` | true/false - whether requested version is installed |
| `ACTIVATION_COMMAND` | Shell command to activate the version manager |
| `SYSTEM_RUBY_VERSION` | System Ruby version (when VERSION_MANAGER=none) |
| `WARNING` | Any warnings about the environment |

## Activation Commands Reference

Use the `ACTIVATION_COMMAND` from detect.sh output. If you need to construct commands manually:

| Manager | Activation Command | Execution Pattern |
|---------|-------------------|-------------------|
| rbenv | `eval "$(rbenv init -)"` | `rbenv exec ruby ...` or activate then run |
| chruby | `source .../chruby.sh && chruby <version>` | Explicit version switch (detect.sh provides full command) |
| rvm | `source "$HOME/.rvm/scripts/rvm"` | Activate then run, or use `~/.rvm/bin/rvm-auto-ruby` |
| asdf (v0.16+) | None needed | `asdf exec ruby ...` |
| asdf (<v0.16) | `source "$HOME/.asdf/asdf.sh"` | `asdf exec ruby ...` |
| mise | None needed | `mise x -- ruby ...` |
| rv | None needed | `rv ruby run -- ...` |
| shadowenv | None needed | `shadowenv exec -- ruby ...` |
| none | None | `ruby ...` (uses PATH) |

## Commands Requiring Activation

All Ruby ecosystem commands need version manager activation:

| Category | Commands |
|----------|----------|
| Core | `ruby`, `irb`, `gem`, `bundle`, `bundler` |
| Build/Task | `rake`, `rails`, `thor` |
| Testing | `rspec`, `minitest`, `cucumber` |
| Linting | `rubocop`, `standardrb`, `reek` |
| LSP/IDE | `ruby-lsp`, `solargraph`, `steep` |
| Debug | `pry`, `byebug`, `debug` |
| Any gem binary | Executables installed via `gem install` or in `Gemfile` |

## Running Ruby Commands

Use `ACTIVATION_COMMAND` from detect.sh, chained with your Ruby command:

```bash
# rbenv
eval "$(rbenv init -)" && bundle install

# chruby (use explicit version, not auto.sh - auto.sh only triggers on cd)
source /usr/local/share/chruby/chruby.sh && chruby ruby-3.3.0 && bundle install

# rvm
source "$HOME/.rvm/scripts/rvm" && bundle install

# asdf (v0.16+)
asdf exec bundle install

# asdf (<v0.16)
source "$HOME/.asdf/asdf.sh" && asdf exec bundle install

# mise
mise x -- bundle install

# rv
rv ruby run -- bundle install

# shadowenv
shadowenv exec -- bundle install
```

## Edge Case Handling

### Multiple version managers installed
Follow the detection priority order. The script returns the highest-priority manager found:
shadowenv > chruby > rbenv > rvm > asdf > rv > mise > none

### Missing .ruby-version file
- If the Gemfile specifies a Ruby version constraint, warn the user
- If no constraint exists, the version manager may fall back to a default
- Recommend creating a `.ruby-version` file for consistency

### Requested version not installed

When `VERSION_AVAILABLE=false`, inform the user with this template:

> The project requires Ruby {PROJECT_RUBY_VERSION} but it is not currently installed.
>
> To install with {VERSION_MANAGER}:
> - **rbenv:** `rbenv install {VERSION}`
> - **rvm:** `rvm install {VERSION}`
> - **asdf:** `asdf install ruby {VERSION}`
> - **mise:** `mise install ruby@{VERSION}`
> - **chruby:** Install manually or use ruby-install: `ruby-install ruby {VERSION}`
>
> Would you like me to run the installation command?

**Important:** Always ask before installing. Do NOT auto-install Ruby versions.

For chruby users, also check if a compatible version exists (same major.minor) in `INSTALLED_RUBIES`.

### Shadowenv trust issues
Shadowenv requires workspace trust. If you see "untrusted shadowenv program" errors:
- Inform the user they need to run `shadowenv trust` in the project directory
- Do not attempt to bypass security

### Version format variations
The project may specify versions as:
- `3.3.0` - semantic version
- `ruby-3.3.0` - with engine prefix
- `truffleruby-21.3.0` - alternative Ruby engine
- `3.3.0-rc1` - pre-release
- `3.3` - major.minor only (matches any patch level)

### CI/Docker environments
If no version manager is detected but Ruby is available, `VERSION_MANAGER=none`. Use the system Ruby directly.

## Troubleshooting

If Ruby commands fail after activation:
1. Re-run detect.sh to verify the environment
2. Check `VERSION_AVAILABLE` - install the required version if false
3. Verify the version manager is properly installed (check `VERSION_MANAGER_PATH`)
4. For chruby: ensure Ruby installations exist in `~/.rubies` or `/opt/rubies`
5. For rvm: check both `~/.rvm` and `/usr/local/rvm` paths
