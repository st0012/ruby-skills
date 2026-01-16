#!/usr/bin/env bash
#
# Detect ALL installed Ruby version managers
# Outputs JSON-like format for easy parsing
#

set -u

# Detection functions (simplified - just check if installed)
check_shadowenv() {
    if [[ -d ".shadowenv.d" ]] && command -v shadowenv &>/dev/null; then
        return 0
    fi
    return 1
}

check_chruby() {
    # chruby doesn't have --version flag. Detect by checking:
    # 1. chruby.sh script exists at known locations
    # 2. Ruby installations exist in ~/.rubies or /opt/rubies

    # Check for chruby.sh script
    local chruby_script=""
    if [[ -f "/opt/homebrew/share/chruby/chruby.sh" ]]; then
        chruby_script="/opt/homebrew/share/chruby/chruby.sh"
    elif [[ -f "/usr/local/share/chruby/chruby.sh" ]]; then
        chruby_script="/usr/local/share/chruby/chruby.sh"
    fi

    # Check for Ruby installations in chruby directories
    local has_rubies=false
    if [[ -d "$HOME/.rubies" ]] && [[ -n "$(ls -A "$HOME/.rubies" 2>/dev/null)" ]]; then
        has_rubies=true
    elif [[ -d "/opt/rubies" ]] && [[ -n "$(ls -A "/opt/rubies" 2>/dev/null)" ]]; then
        has_rubies=true
    fi

    # chruby is available if script exists OR rubies directory has installations
    if [[ -n "$chruby_script" ]] || $has_rubies; then
        return 0
    fi
    return 1
}

check_rbenv() {
    if timeout 1 bash -lc "rbenv --version" 2>/dev/null | grep -q "rbenv"; then
        return 0
    fi
    return 1
}

check_rvm() {
    if timeout 1 bash -lc "rvm --version" 2>/dev/null | grep -q "rvm"; then
        return 0
    fi
    return 1
}

check_asdf() {
    if timeout 1 bash -lc "asdf --version" 2>/dev/null | grep -qE "^(v|[0-9])"; then
        return 0
    fi
    return 1
}

check_rv() {
    if timeout 1 bash -lc "rv --version" 2>/dev/null | grep -q "rv"; then
        return 0
    fi
    return 1
}

check_mise() {
    for path in "$HOME/.local/bin/mise" "/opt/homebrew/bin/mise" "/usr/local/bin/mise" "/usr/bin/mise"; do
        if [[ -x "$path" ]]; then
            return 0
        fi
    done
    if command -v mise &>/dev/null; then
        return 0
    fi
    return 1
}

# Main
managers=()

check_shadowenv && managers+=("shadowenv")
check_chruby && managers+=("chruby")
check_rbenv && managers+=("rbenv")
check_rvm && managers+=("rvm")
check_asdf && managers+=("asdf")
check_rv && managers+=("rv")
check_mise && managers+=("mise")

# Output as comma-separated list
echo "INSTALLED_MANAGERS=$(IFS=,; echo "${managers[*]}")"
echo "MANAGER_COUNT=${#managers[@]}"
