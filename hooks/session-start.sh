#!/usr/bin/env bash
# SessionStart hook for ruby-skills plugin
# Detects Ruby projects and injects context to use ruby-version-manager skill

set -euo pipefail

# Check if current directory is a Ruby project
is_ruby_project() {
    [ -f "Gemfile" ] || [ -f ".ruby-version" ] || [ -f ".tool-versions" ] || [ -f ".mise.toml" ]
}

# If not a Ruby project, exit silently (no context injection)
if ! is_ruby_project; then
    echo '{}'
    exit 0
fi

# Resolve symlinks to get real script location
resolve_path() {
    local path="$1"
    if command -v readlink >/dev/null 2>&1; then
        # Try GNU readlink -f first, fall back to manual resolution
        readlink -f "$path" 2>/dev/null || {
            # macOS: readlink doesn't have -f, resolve manually
            local dir file
            while [ -L "$path" ]; do
                dir="$(dirname "$path")"
                file="$(readlink "$path")"
                [[ "$file" == /* ]] && path="$file" || path="$dir/$file"
            done
            echo "$path"
        }
    else
        echo "$path"
    fi
}

REAL_SCRIPT="$(resolve_path "${BASH_SOURCE[0]:-$0}")"
SCRIPT_DIR="$(cd "$(dirname "$REAL_SCRIPT")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Read the skill content
skill_content=$(cat "${PLUGIN_ROOT}/skills/ruby-version-manager/SKILL.md" 2>/dev/null || echo "")

# If skill not found, exit silently
if [ -z "$skill_content" ]; then
    echo '{}'
    exit 0
fi

# Build the context message
context_message="<RUBY_PROJECT_DETECTED>
This is a Ruby project. You MUST use the ruby-version-manager skill.

**REQUIRED BEFORE ANY RUBY COMMAND:**
1. Run the detect.sh script: ${PLUGIN_ROOT}/skills/ruby-version-manager/detect.sh
2. Use the ACTIVATION_COMMAND from the output
3. Chain activation with your command using &&

**DO NOT:**
- Run ruby, bundle, gem, rake, rails, rspec without activation
- Assume which version manager is installed
- Skip detection even if you think you know the setup

**The skill content is below. Follow it exactly.**

---

${skill_content}
</RUBY_PROJECT_DETECTED>"

# Use jq for proper JSON escaping if available, otherwise fall back to basic escaping
if command -v jq &>/dev/null; then
    # jq handles all JSON escaping properly
    jq -n --arg context "$context_message" '{
        hookSpecificOutput: {
            hookEventName: "SessionStart",
            additionalContext: $context
        }
    }'
else
    # Fallback: basic escaping for systems without jq
    escape_for_json() {
        local input="$1"
        local output=""
        local i char
        for (( i=0; i<${#input}; i++ )); do
            char="${input:$i:1}"
            case "$char" in
                '\\') output+='\\\\' ;;
                '"') output+='\"' ;;
                $'\n') output+='\\n' ;;
                $'\r') output+='\\r' ;;
                $'\t') output+='\\t' ;;
                $'\b') output+='\\b' ;;
                *) output+="$char" ;;
            esac
        done
        printf '%s' "$output"
    }

    context_escaped=$(escape_for_json "$context_message")

    cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "${context_escaped}"
  }
}
EOF
fi

exit 0
