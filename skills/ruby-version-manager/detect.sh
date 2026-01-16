#!/usr/bin/env bash
#
# Ruby Version Manager Detection Script
# Detects installed version managers and project Ruby requirements
#

set -u
# Note: -e and pipefail are intentionally omitted to handle grep returning 1 when no match

# Detection priority order (from ruby-lsp):
# shadowenv > chruby > rbenv > rvm > asdf > rv > mise > none

VERSION_MANAGER="none"
VERSION_MANAGER_PATH=""
PROJECT_RUBY_VERSION=""
PROJECT_VERSION_SOURCE=""
RUBY_ENGINE="ruby"
INSTALLED_RUBIES=""
VERSION_AVAILABLE="false"
ACTIVATION_COMMAND=""
SYSTEM_RUBY_VERSION=""
WARNING=""

# Parse Ruby version string
# Supports: 3.3.0, ruby-3.3.0, truffleruby-21.3.0, 3.3.0-rc1, 3.3
parse_ruby_version() {
    local version_str="$1"
    # Extract engine and version using regex pattern
    if [[ "$version_str" =~ ^([A-Za-z]+)-(.+)$ ]]; then
        RUBY_ENGINE="${BASH_REMATCH[1]}"
        PROJECT_RUBY_VERSION="${BASH_REMATCH[2]}"
    else
        RUBY_ENGINE="ruby"
        PROJECT_RUBY_VERSION="$version_str"
    fi
}

# Get project Ruby version from various sources
detect_project_version() {
    # Check .ruby-version
    if [[ -f ".ruby-version" ]]; then
        local version
        version=$(cat ".ruby-version" | tr -d '[:space:]')
        if [[ -n "$version" ]]; then
            parse_ruby_version "$version"
            PROJECT_VERSION_SOURCE=".ruby-version"
            return 0
        fi
    fi

    # Check .tool-versions (asdf/mise format)
    if [[ -f ".tool-versions" ]]; then
        local version
        version=$(grep -E "^ruby\s+" ".tool-versions" 2>/dev/null | awk '{print $2}' | tr -d '[:space:]')
        if [[ -n "$version" ]]; then
            parse_ruby_version "$version"
            PROJECT_VERSION_SOURCE=".tool-versions"
            return 0
        fi
    fi

    # Check .mise.toml
    if [[ -f ".mise.toml" ]]; then
        local version
        # Parse ruby = "version" or [tools] ruby = "version"
        version=$(grep -E '^\s*ruby\s*=' ".mise.toml" 2>/dev/null | head -1 | sed 's/.*=[[:space:]]*["'"'"']\([^"'"'"']*\)["'"'"'].*/\1/' | tr -d '[:space:]')
        if [[ -n "$version" ]]; then
            parse_ruby_version "$version"
            PROJECT_VERSION_SOURCE=".mise.toml"
            return 0
        fi
    fi

    # Check Gemfile for ruby constraint
    if [[ -f "Gemfile" ]]; then
        local version
        # Match: ruby "3.3.0" or ruby '3.3.0' or ruby "~> 3.3"
        version=$(grep -E "^\s*ruby\s+['\"]" "Gemfile" 2>/dev/null | head -1 | sed 's/.*['"'"'"]\([^'"'"'"]*\)['"'"'"].*/\1/' | tr -d '[:space:]')
        if [[ -n "$version" ]]; then
            # Remove version constraints like ~>, >=, etc.
            version=$(echo "$version" | sed 's/^[~>=<]*//')
            parse_ruby_version "$version"
            PROJECT_VERSION_SOURCE="Gemfile"
            return 0
        fi
    fi

    return 1
}

# Check if a command exists with timeout
command_exists() {
    local cmd="$1"
    timeout 1 bash -c "command -v $cmd" &>/dev/null 2>&1
}

# Run command with timeout through user's shell
run_with_timeout() {
    timeout 1 bash -lc "$1" 2>/dev/null || true
}

# Detect shadowenv
detect_shadowenv() {
    if [[ -d ".shadowenv.d" ]]; then
        if command_exists shadowenv; then
            VERSION_MANAGER="shadowenv"
            VERSION_MANAGER_PATH=$(command -v shadowenv 2>/dev/null || echo "")
            ACTIVATION_COMMAND="shadowenv exec --"
            return 0
        fi
    fi
    return 1
}

# Detect chruby
detect_chruby() {
    if run_with_timeout "chruby --version" | grep -q "chruby"; then
        VERSION_MANAGER="chruby"

        # Find chruby installation path
        if [[ -f "/opt/homebrew/share/chruby/chruby.sh" ]]; then
            VERSION_MANAGER_PATH="/opt/homebrew/share/chruby"
            ACTIVATION_COMMAND="source /opt/homebrew/share/chruby/chruby.sh && source /opt/homebrew/share/chruby/auto.sh"
        elif [[ -f "/usr/local/share/chruby/chruby.sh" ]]; then
            VERSION_MANAGER_PATH="/usr/local/share/chruby"
            ACTIVATION_COMMAND="source /usr/local/share/chruby/chruby.sh && source /usr/local/share/chruby/auto.sh"
        elif [[ -f "/usr/share/chruby/chruby.sh" ]]; then
            VERSION_MANAGER_PATH="/usr/share/chruby"
            ACTIVATION_COMMAND="source /usr/share/chruby/chruby.sh && source /usr/share/chruby/auto.sh"
        fi

        # Find installed rubies
        local rubies=()
        for dir in "$HOME/.rubies" "/opt/rubies"; do
            if [[ -d "$dir" ]]; then
                for ruby_dir in "$dir"/*; do
                    if [[ -d "$ruby_dir" && -x "$ruby_dir/bin/ruby" ]]; then
                        rubies+=("$(basename "$ruby_dir")")
                    fi
                done
            fi
        done
        INSTALLED_RUBIES=$(IFS=,; echo "${rubies[*]}")
        return 0
    fi
    return 1
}

# Detect rbenv
detect_rbenv() {
    if run_with_timeout "rbenv --version" | grep -q "rbenv"; then
        VERSION_MANAGER="rbenv"
        VERSION_MANAGER_PATH=$(run_with_timeout "rbenv root" || echo "$HOME/.rbenv")
        ACTIVATION_COMMAND='eval "$(rbenv init -)"'

        # Get installed versions
        local versions
        versions=$(run_with_timeout "rbenv versions --bare" || echo "")
        INSTALLED_RUBIES=$(echo "$versions" | tr '\n' ',' | sed 's/,$//')
        return 0
    fi
    return 1
}

# Detect rvm
detect_rvm() {
    if run_with_timeout "rvm --version" | grep -q "rvm"; then
        VERSION_MANAGER="rvm"

        # Find rvm path
        if [[ -d "$HOME/.rvm" ]]; then
            VERSION_MANAGER_PATH="$HOME/.rvm"
            ACTIVATION_COMMAND="source \"\$HOME/.rvm/scripts/rvm\""
        elif [[ -d "/usr/local/rvm" ]]; then
            VERSION_MANAGER_PATH="/usr/local/rvm"
            ACTIVATION_COMMAND="source /usr/local/rvm/scripts/rvm"
        elif [[ -d "/usr/share/rvm" ]]; then
            VERSION_MANAGER_PATH="/usr/share/rvm"
            ACTIVATION_COMMAND="source /usr/share/rvm/scripts/rvm"
        fi

        # Get installed versions
        local versions
        versions=$(run_with_timeout "rvm list strings" || echo "")
        INSTALLED_RUBIES=$(echo "$versions" | tr '\n' ',' | sed 's/,$//')
        return 0
    fi
    return 1
}

# Detect asdf
detect_asdf() {
    if run_with_timeout "asdf --version" | grep -qE "^(v|[0-9])"; then
        VERSION_MANAGER="asdf"
        VERSION_MANAGER_PATH="${ASDF_DIR:-$HOME/.asdf}"

        # Check asdf version for activation command
        local asdf_version
        asdf_version=$(run_with_timeout "asdf --version" | grep -oE "[0-9]+\.[0-9]+" | head -1)
        local major_minor
        major_minor=$(echo "$asdf_version" | cut -d. -f1,2)

        # v0.16+ doesn't need sourcing
        if [[ "$(echo "$major_minor >= 0.16" | bc -l 2>/dev/null || echo 0)" == "1" ]]; then
            ACTIVATION_COMMAND="asdf exec"
        else
            ACTIVATION_COMMAND="source \"\$HOME/.asdf/asdf.sh\" && asdf exec"
        fi

        # Get installed ruby versions
        local versions
        versions=$(run_with_timeout "asdf list ruby" 2>/dev/null | grep -oE "[0-9]+\.[0-9]+\.[0-9]+" || echo "")
        INSTALLED_RUBIES=$(echo "$versions" | tr '\n' ',' | sed 's/,$//')
        return 0
    fi
    return 1
}

# Detect rv
detect_rv() {
    if run_with_timeout "rv --version" | grep -q "rv"; then
        VERSION_MANAGER="rv"
        VERSION_MANAGER_PATH=$(command -v rv 2>/dev/null || echo "")
        ACTIVATION_COMMAND="rv ruby run --"

        # rv auto-detects installations, list what's available
        local versions
        versions=$(run_with_timeout "rv ruby list" 2>/dev/null | grep -oE "[0-9]+\.[0-9]+\.[0-9]+" || echo "")
        INSTALLED_RUBIES=$(echo "$versions" | tr '\n' ',' | sed 's/,$//')
        return 0
    fi
    return 1
}

# Detect mise
detect_mise() {
    local mise_path=""

    # Check predefined paths (mise doesn't always have --version in PATH)
    for path in "$HOME/.local/bin/mise" "/opt/homebrew/bin/mise" "/usr/local/bin/mise" "/usr/bin/mise"; do
        if [[ -x "$path" ]]; then
            mise_path="$path"
            break
        fi
    done

    # Also check if mise is in PATH
    if [[ -z "$mise_path" ]] && command_exists mise; then
        mise_path=$(command -v mise 2>/dev/null)
    fi

    if [[ -n "$mise_path" ]]; then
        VERSION_MANAGER="mise"
        VERSION_MANAGER_PATH="$mise_path"
        ACTIVATION_COMMAND="mise x --"

        # Get installed ruby versions
        local versions
        versions=$("$mise_path" list ruby 2>/dev/null | grep -oE "[0-9]+\.[0-9]+\.[0-9]+" || echo "")
        INSTALLED_RUBIES=$(echo "$versions" | tr '\n' ',' | sed 's/,$//')
        return 0
    fi
    return 1
}

# Check if requested version is available
check_version_available() {
    if [[ -z "$PROJECT_RUBY_VERSION" || -z "$INSTALLED_RUBIES" ]]; then
        return
    fi

    # Check exact match or prefix match (for versions like "3.3" matching "3.3.0")
    local version_pattern="$PROJECT_RUBY_VERSION"

    # If version has engine prefix, include it in search
    local search_version="$PROJECT_RUBY_VERSION"
    if [[ "$RUBY_ENGINE" != "ruby" ]]; then
        search_version="${RUBY_ENGINE}-${PROJECT_RUBY_VERSION}"
    fi

    # Check if version is in installed list
    if echo "$INSTALLED_RUBIES" | grep -qE "(^|,)${search_version}(,|$)"; then
        VERSION_AVAILABLE="true"
    elif echo "$INSTALLED_RUBIES" | grep -qE "(^|,)ruby-${PROJECT_RUBY_VERSION}(,|$)"; then
        VERSION_AVAILABLE="true"
    elif echo "$INSTALLED_RUBIES" | grep -qE "(^|,)${PROJECT_RUBY_VERSION}\.[0-9]+(,|$)"; then
        # Match "3.3" to "3.3.0"
        VERSION_AVAILABLE="true"
    elif echo "$INSTALLED_RUBIES" | grep -qE "(^|,)${PROJECT_RUBY_VERSION}(,|$)"; then
        VERSION_AVAILABLE="true"
    fi
}

# Get system Ruby version
get_system_ruby() {
    if command_exists ruby; then
        SYSTEM_RUBY_VERSION=$(ruby -v 2>/dev/null | grep -oE "[0-9]+\.[0-9]+\.[0-9]+" | head -1 || echo "")
    fi
}

# Main detection logic
main() {
    # Detect project version first
    detect_project_version || true

    # Detect version manager in priority order
    if detect_shadowenv; then
        :
    elif detect_chruby; then
        :
    elif detect_rbenv; then
        :
    elif detect_rvm; then
        :
    elif detect_asdf; then
        :
    elif detect_rv; then
        :
    elif detect_mise; then
        :
    else
        VERSION_MANAGER="none"
        get_system_ruby

        if [[ -n "$PROJECT_RUBY_VERSION" && -n "$SYSTEM_RUBY_VERSION" ]]; then
            if [[ "$PROJECT_RUBY_VERSION" != "$SYSTEM_RUBY_VERSION"* ]]; then
                WARNING="No version manager detected. System Ruby is $SYSTEM_RUBY_VERSION. Project requires $PROJECT_RUBY_VERSION."
                VERSION_AVAILABLE="false"
            else
                VERSION_AVAILABLE="true"
            fi
        elif [[ -n "$SYSTEM_RUBY_VERSION" ]]; then
            VERSION_AVAILABLE="true"
        fi
    fi

    # Check if requested version is available
    check_version_available

    # Add warning for missing version file
    if [[ -z "$PROJECT_VERSION_SOURCE" && -f "Gemfile" ]]; then
        if [[ -z "$WARNING" ]]; then
            WARNING="No .ruby-version file found. Consider creating one for consistent Ruby version across tools."
        fi
    fi

    # Output results
    echo "VERSION_MANAGER=$VERSION_MANAGER"
    echo "VERSION_MANAGER_PATH=$VERSION_MANAGER_PATH"
    echo "PROJECT_RUBY_VERSION=$PROJECT_RUBY_VERSION"
    echo "PROJECT_VERSION_SOURCE=$PROJECT_VERSION_SOURCE"
    echo "RUBY_ENGINE=$RUBY_ENGINE"
    echo "INSTALLED_RUBIES=$INSTALLED_RUBIES"
    echo "VERSION_AVAILABLE=$VERSION_AVAILABLE"
    echo "ACTIVATION_COMMAND=$ACTIVATION_COMMAND"
    if [[ -n "$SYSTEM_RUBY_VERSION" ]]; then
        echo "SYSTEM_RUBY_VERSION=$SYSTEM_RUBY_VERSION"
    fi
    if [[ -n "$WARNING" ]]; then
        echo "WARNING=$WARNING"
    fi
}

main
exit 0
