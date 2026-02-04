#!/usr/bin/env bash

set -u

# Default values
RUBOCOP_AVAILABLE="false"
RUBOCOP_VERSION="unknown"
RUBOCOP_CONFIG_FILE="none"
RUBOCOP_CONFIG_PATH="default"
RUBOCOP_EXECUTABLE="none"
AUTO_CORRECT_AVAILABLE="false"

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to safely get command output with timeout
safe_command() {
    timeout 3 bash -c "$1" 2>/dev/null || echo ""
}

# Check if we're in a Ruby project (has Gemfile, .ruby-version, etc.)
is_ruby_project() {
    [ -f "Gemfile" ] || [ -f ".ruby-version" ] || [ -f ".tool-versions" ] || [ -f "*.gemspec" ]
}

# Check if RuboCop is in Gemfile
rubocop_in_gemfile() {
    if [ -f "Gemfile" ]; then
        grep -q "rubocop" Gemfile 2>/dev/null
    else
        false
    fi
}

# Check bundler availability
bundler_available() {
    command_exists bundle && [ -f "Gemfile" ] && [ -f "Gemfile.lock" ]
}

# Detect RuboCop executable and availability
detect_rubocop_executable() {
    # First, try bundle exec if appropriate
    if bundler_available && rubocop_in_gemfile; then
        if safe_command "bundle exec rubocop --version" >/dev/null 2>&1; then
            RUBOCOP_EXECUTABLE="bundle exec rubocop"
            RUBOCOP_AVAILABLE="true"
            # Get version from bundle exec
            RUBOCOP_VERSION=$(safe_command "bundle exec rubocop --version" | head -1 | awk '{print $NF}')
            return 0
        fi
    fi

    # Fallback to global rubocop
    if command_exists rubocop; then
        if safe_command "rubocop --version" >/dev/null 2>&1; then
            RUBOCOP_EXECUTABLE="rubocop"
            RUBOCOP_AVAILABLE="true"
            # Get version from global rubocop
            RUBOCOP_VERSION=$(safe_command "rubocop --version" | head -1 | awk '{print $NF}')
            return 0
        fi
    fi

    return 1
}

# Find RuboCop configuration file
find_rubocop_config() {
    local current_dir="$PWD"

    # Check common config file names in order of preference
    local config_files=(".rubocop.yml" ".rubocop_todo.yml" "rubocop.yml")

    # Check current directory first
    for config_file in "${config_files[@]}"; do
        if [ -f "$config_file" ]; then
            RUBOCOP_CONFIG_FILE="$config_file"
            RUBOCOP_CONFIG_PATH="$current_dir/$config_file"
            return 0
        fi
    done

    # Walk up directories to find config file
    local dir="$current_dir"
    while [ "$dir" != "/" ]; do
        dir=$(dirname "$dir")
        for config_file in "${config_files[@]}"; do
            if [ -f "$dir/$config_file" ]; then
                RUBOCOP_CONFIG_FILE="$config_file"
                RUBOCOP_CONFIG_PATH="$dir/$config_file"
                return 0
            fi
        done
    done

    # Check user home directory
    for config_file in "${config_files[@]}"; do
        if [ -f "$HOME/$config_file" ]; then
            RUBOCOP_CONFIG_FILE="$config_file"
            RUBOCOP_CONFIG_PATH="$HOME/$config_file"
            return 0
        fi
    done

    return 1
}

# Check if auto-correct is available and safe
check_auto_correct() {
    if [ "$RUBOCOP_AVAILABLE" = "true" ]; then
        # Check if --auto-correct is supported (it is in modern RuboCop versions)
        if safe_command "$RUBOCOP_EXECUTABLE --help" | grep -q "auto-correct" 2>/dev/null; then
            AUTO_CORRECT_AVAILABLE="true"
        fi
    fi
}

# Main detection logic
main() {
    # Only proceed if we're likely in a Ruby project or RuboCop is explicitly available
    if ! is_ruby_project && ! command_exists rubocop; then
        # Not a Ruby project and no global RuboCop, skip detection
        echo "RUBOCOP_AVAILABLE=false"
        echo "RUBOCOP_VERSION=unknown"
        echo "RUBOCOP_CONFIG_FILE=none"
        echo "RUBOCOP_CONFIG_PATH=default"
        echo "RUBOCOP_EXECUTABLE=none"
        echo "AUTO_CORRECT_AVAILABLE=false"
        return 0
    fi

    # Detect RuboCop executable
    detect_rubocop_executable

    # If RuboCop is available, find configuration and check features
    if [ "$RUBOCOP_AVAILABLE" = "true" ]; then
        find_rubocop_config
        check_auto_correct
    fi

    # Ensure version is not empty
    if [ -z "$RUBOCOP_VERSION" ] || [ "$RUBOCOP_VERSION" = "" ]; then
        RUBOCOP_VERSION="unknown"
    fi

    # Output results
    echo "RUBOCOP_AVAILABLE=$RUBOCOP_AVAILABLE"
    echo "RUBOCOP_VERSION=$RUBOCOP_VERSION"
    echo "RUBOCOP_CONFIG_FILE=$RUBOCOP_CONFIG_FILE"
    echo "RUBOCOP_CONFIG_PATH=$RUBOCOP_CONFIG_PATH"
    echo "RUBOCOP_EXECUTABLE=$RUBOCOP_EXECUTABLE"
    echo "AUTO_CORRECT_AVAILABLE=$AUTO_CORRECT_AVAILABLE"
}

# Execute main function
main "$@"