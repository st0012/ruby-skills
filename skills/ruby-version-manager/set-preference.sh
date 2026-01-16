#!/usr/bin/env bash
#
# Set Ruby version manager preference
# Usage: set-preference.sh <manager>
#

set -euo pipefail

MANAGER="${1:-}"

if [[ -z "$MANAGER" ]]; then
    echo "Usage: set-preference.sh <manager>"
    echo "  manager: shadowenv, chruby, rbenv, rvm, asdf, rv, mise"
    exit 1
fi

# Validate manager name
valid_managers="shadowenv chruby rbenv rvm asdf rv mise"
if [[ ! " $valid_managers " =~ " $MANAGER " ]]; then
    echo "ERROR: Invalid manager '$MANAGER'"
    echo "Valid managers: $valid_managers"
    exit 1
fi

# Create user-level preference file
mkdir -p "$HOME/.config/ruby-skills"
cat > "$HOME/.config/ruby-skills/preference.json" << EOF
{
  "preferred_manager": "$MANAGER",
  "set_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF
echo "Set preference to '$MANAGER' in ~/.config/ruby-skills/preference.json"
