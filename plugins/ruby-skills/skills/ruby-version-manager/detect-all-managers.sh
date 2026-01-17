#!/usr/bin/env bash
#
# Detect ALL installed Ruby version managers
# Can be sourced by other scripts or run standalone
#

set -u

# Detection functions
_check_shadowenv() {
    [[ -d ".shadowenv.d" ]] && command -v shadowenv &>/dev/null
}

_check_chruby() {
    # chruby doesn't have --version flag. Detect by checking:
    # 1. chruby.sh script exists at known locations
    # 2. Ruby installations exist in ~/.rubies or /opt/rubies
    [[ -f "/opt/homebrew/share/chruby/chruby.sh" ]] ||
    [[ -f "/usr/local/share/chruby/chruby.sh" ]] ||
    [[ -f "/usr/share/chruby/chruby.sh" ]] ||
    { [[ -d "$HOME/.rubies" ]] && [[ -n "$(ls -A "$HOME/.rubies" 2>/dev/null)" ]]; } ||
    { [[ -d "/opt/rubies" ]] && [[ -n "$(ls -A "/opt/rubies" 2>/dev/null)" ]]; }
}

_check_rbenv() {
    timeout 1 bash -lc "rbenv --version" 2>/dev/null | grep -q "rbenv"
}

_check_rvm() {
    timeout 1 bash -lc "rvm --version" 2>/dev/null | grep -q "rvm"
}

_check_asdf() {
    timeout 1 bash -lc "asdf --version" 2>/dev/null | grep -qE "^(v|[0-9])"
}

_check_rv() {
    timeout 1 bash -lc "rv --version" 2>/dev/null | grep -q "rv"
}

_check_mise() {
    for path in "$HOME/.local/bin/mise" "/opt/homebrew/bin/mise" "/usr/local/bin/mise" "/usr/bin/mise"; do
        [[ -x "$path" ]] && return 0
    done
    command -v mise &>/dev/null
}

# Main function - returns space-separated list of installed managers
get_installed_managers() {
    local managers=()

    _check_shadowenv && managers+=("shadowenv")
    _check_chruby && managers+=("chruby")
    _check_rbenv && managers+=("rbenv")
    _check_rvm && managers+=("rvm")
    _check_asdf && managers+=("asdf")
    _check_rv && managers+=("rv")
    _check_mise && managers+=("mise")

    echo "${managers[*]}"
}

# Run standalone if executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    managers=$(get_installed_managers)
    manager_array=($managers)

    echo "INSTALLED_MANAGERS=$(IFS=,; echo "${manager_array[*]}")"
    echo "MANAGER_COUNT=${#manager_array[@]}"
fi
