# Ruby Version Manager Skill

Technical reference for contributors and those curious about the detection internals.

Detects and configures Ruby version managers so Claude Code uses the correct Ruby environment for your project.

**Supported managers:** chruby, rbenv, rvm, asdf, mise, rv, shadowenv

## How It Works

```
Session Start (Ruby project detected)
        │
        ▼
SessionStart hook triggers detection
        │
        ▼
detect.sh runs:
  • Checks stored preference (~/.config/ruby-skills/preference.json)
  • Detects installed version managers
  • Finds project Ruby version (.ruby-version, .tool-versions, .mise.toml, Gemfile)
  • Returns ACTIVATION_COMMAND
        │
        ├── Multiple managers, no preference
        │       → Claude asks which to use, stores choice
        │
        └── Single or preferred manager
                → Claude chains ACTIVATION_COMMAND with Ruby commands
```

## Why Activation Is Chained

Claude Code runs each Bash command in a fresh shell — environment changes don't persist between commands.

```bash
# Won't work — environment is lost between commands:
source /usr/local/share/chruby/chruby.sh && chruby ruby-3.3.0
bundle install   # ← Fresh shell — activation was lost

# Works — single command preserves environment:
source /usr/local/share/chruby/chruby.sh && chruby ruby-3.3.0 && bundle install
```

The skill instructs Claude to chain activation with every Ruby invocation, so users don't need to think about this.

## Files

| File | Purpose |
|------|---------|
| `detect.sh` | Detects version manager, project version, and outputs activation command |
| `detect-all-managers.sh` | Finds all installed managers (used when no preference is stored) |
| `set-preference.sh` | Stores manager preference to `~/.config/ruby-skills/preference.json` |
| `SKILL.md` | Instructions for Claude (loaded as skill context) |
