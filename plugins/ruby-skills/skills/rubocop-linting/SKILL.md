---
name: rubocop-linting
description: Use when reviewing or linting Ruby code with RuboCop. Automatically detects RuboCop configuration and provides formatted output.
---

# RuboCop Linting Skill

Use this skill when you need to lint Ruby code with RuboCop. The skill automatically handles Ruby environment detection, RuboCop configuration discovery, and provides formatted output suitable for code review and fixing.

## When to Use

Use this skill automatically when:
- You're reviewing Ruby code for style violations
- You need to check code quality before committing
- User asks you to "lint", "check style", or "run rubocop"
- You're fixing style violations in Ruby files
- Working in a Ruby project and code quality checks are needed

## Prerequisites

**This skill depends on the `ruby-version-manager` skill.** Always run the version manager detection first to ensure the correct Ruby environment is activated.

## Usage

### 1. Detect Ruby Environment (Required First Step)

```bash
# Run ruby-version-manager detection first
/path/to/ruby-skills/skills/ruby-version-manager/detect.sh
```

### 2. Detect RuboCop Configuration

```bash
# Detect RuboCop availability and configuration
/path/to/ruby-skills/skills/rubocop-linting/detect.sh
```

### 3. Run RuboCop Linting

```bash
# Run RuboCop with detected configuration
/path/to/ruby-skills/skills/rubocop-linting/run.sh [options] [files...]
```

## Detection Output Variables

The `detect.sh` script outputs these variables:

| Variable | Description | Example Values |
|----------|-------------|----------------|
| `RUBOCOP_AVAILABLE` | Whether RuboCop is available | `true`, `false` |
| `RUBOCOP_VERSION` | Version of RuboCop detected | `1.45.1`, `unknown` |
| `RUBOCOP_CONFIG_FILE` | Configuration file found | `.rubocop.yml`, `.rubocop_todo.yml`, `none` |
| `RUBOCOP_CONFIG_PATH` | Full path to config file | `/project/.rubocop.yml` |
| `RUBOCOP_EXECUTABLE` | How to invoke RuboCop | `bundle exec rubocop`, `rubocop` |
| `AUTO_CORRECT_AVAILABLE` | Whether auto-correct is safe | `true`, `false` |

## Linting Output Variables

The `run.sh` script outputs these variables after execution:

| Variable | Description | Example Values |
|----------|-------------|----------------|
| `LINT_STATUS` | Overall linting result | `passed`, `failed`, `error` |
| `OFFENSE_COUNT` | Number of style violations | `0`, `42`, `unknown` |
| `FILES_CHECKED` | Number of files checked | `15` |
| `CORRECTABLE_OFFENSES` | Number of auto-correctable issues | `12` |

## Common Usage Patterns

### Check Specific Files

```bash
# Activate Ruby environment and run RuboCop on specific files
ACTIVATION_COMMAND && /path/to/rubocop-linting/run.sh app/models/user.rb lib/helper.rb
```

### Auto-Correct Safe Violations

```bash
# Run with auto-correct for safe violations only
ACTIVATION_COMMAND && /path/to/rubocop-linting/run.sh --auto-correct
```

### Check All Ruby Files

```bash
# Lint entire project (respects .rubocop.yml excludes)
ACTIVATION_COMMAND && /path/to/rubocop-linting/run.sh
```

### Format Output for Review

```bash
# Generate formatted output for code review
ACTIVATION_COMMAND && /path/to/rubocop-linting/run.sh --format progress --display-cop-names
```

## Integration with Ruby Environment

This skill integrates with the Ruby version manager detection:

1. **Always run ruby-version-manager first** to get `ACTIVATION_COMMAND`
2. **Chain the activation command** before running RuboCop: `ACTIVATION_COMMAND && rubocop ...`
3. **Use the project's Ruby version** to ensure consistent gem dependencies

Example complete workflow:

```bash
# 1. Detect Ruby environment
VERSION_OUTPUT=$(ruby-version-manager/detect.sh)
ACTIVATION_COMMAND=$(echo "$VERSION_OUTPUT" | grep "ACTIVATION_COMMAND=" | cut -d'=' -f2-)

# 2. Detect RuboCop configuration
RUBOCOP_OUTPUT=$(ACTIVATION_COMMAND && rubocop-linting/detect.sh)
RUBOCOP_EXECUTABLE=$(echo "$RUBOCOP_OUTPUT" | grep "RUBOCOP_EXECUTABLE=" | cut -d'=' -f2-)

# 3. Run linting
$ACTIVATION_COMMAND && $RUBOCOP_EXECUTABLE app/models/user.rb
```

## Configuration Discovery

The skill automatically finds RuboCop configuration in this order:

1. `.rubocop.yml` in current directory
2. `.rubocop_todo.yml` in current directory
3. `.rubocop.yml` in parent directories (walking up)
4. Default RuboCop configuration

## Handling Common Scenarios

### Bundled vs Global RuboCop

The detection script determines whether to use:
- `bundle exec rubocop` (if Gemfile contains rubocop)
- `rubocop` (global installation)

### Missing RuboCop

If RuboCop is not available, the detection script outputs:
```
RUBOCOP_AVAILABLE=false
RUBOCOP_EXECUTABLE=none
```

The user should be prompted to:
1. Add `gem 'rubocop'` to Gemfile and run `bundle install`
2. Or install globally with `gem install rubocop`

### No Configuration File

RuboCop will use its default configuration. The detection script outputs:
```
RUBOCOP_CONFIG_FILE=none
RUBOCOP_CONFIG_PATH=default
```

### Large Codebases

For large projects, consider:
- Using `--parallel` flag for faster linting
- Focusing on specific directories or changed files
- Using incremental linting strategies

## Troubleshooting

### "Command not found: rubocop"

**Problem**: RuboCop is not available in the current Ruby environment.

**Solutions**:
1. Check if it's in the Gemfile: `grep rubocop Gemfile`
2. Install via bundle: `bundle add rubocop` or add to Gemfile manually
3. Install globally: `gem install rubocop`

### "Configuration file not found"

**Problem**: Custom configuration file specified but doesn't exist.

**Solutions**:
1. Create `.rubocop.yml` with basic configuration
2. Remove custom `--config` flags to use defaults
3. Check file permissions

### "Incompatible Ruby version"

**Problem**: RuboCop version requires different Ruby version.

**Solutions**:
1. Check RuboCop version compatibility
2. Update RuboCop: `bundle update rubocop`
3. Use compatible RuboCop version in Gemfile

### "Bundle not found"

**Problem**: Using `bundle exec rubocop` but Bundler not available.

**Solutions**:
1. Run `gem install bundler`
2. Fall back to global rubocop installation
3. Ensure correct Ruby environment is activated