#!/usr/bin/env bash
# Pre-check ruby-lsp installation status at session start
# Provides early warnings to user about missing dependencies

set -u

# Find ruby-skills detect.sh
DETECT_SCRIPT=$(ls ~/.claude/plugins/cache/*/ruby-skills/*/skills/ruby-version-manager/detect.sh 2>/dev/null | head -1)

if [[ -z "$DETECT_SCRIPT" ]]; then
    echo "ruby-lsp plugin requires ruby-skills. Install: claude plugin install ruby-skills" >&2
    exit 0
fi

# Run detection
DETECT_OUTPUT=$("$DETECT_SCRIPT" 2>/dev/null) || true

# If user needs to choose manager, let them know
if echo "$DETECT_OUTPUT" | grep -q "NEEDS_USER_CHOICE=true"; then
    MANAGERS=$(echo "$DETECT_OUTPUT" | grep "AVAILABLE_MANAGERS=" | cut -d= -f2)
    SET_PREF_SCRIPT="$(dirname "$DETECT_SCRIPT")/set-preference.sh"
    echo "ruby-lsp: Multiple Ruby version managers detected: $MANAGERS" >&2
    echo "Set preference: $SET_PREF_SCRIPT <manager>" >&2
    exit 0
fi

# Parse detection output
ACTIVATION_COMMAND=$(echo "$DETECT_OUTPUT" | grep "^ACTIVATION_COMMAND=" | cut -d= -f2-)
PROJECT_RUBY=$(echo "$DETECT_OUTPUT" | grep "^PROJECT_RUBY_VERSION=" | cut -d= -f2)

# Check if ruby-lsp is installed for this Ruby version
# Run in subshell with set +u to isolate from parent's set -u (some version managers use undefined vars)
if [[ -n "$ACTIVATION_COMMAND" ]]; then
    if ! (set +u; eval "$ACTIVATION_COMMAND && command -v ruby-lsp") &>/dev/null; then
        echo "ruby-lsp: gem not installed for Ruby ${PROJECT_RUBY:-unknown}. Will auto-install on first use." >&2
    fi
fi

exit 0
