#!/usr/bin/env bash

set -u

# Default values
LINT_STATUS="error"
OFFENSE_COUNT="unknown"
FILES_CHECKED="unknown"
CORRECTABLE_OFFENSES="unknown"

# Script directory for sourcing detect.sh
SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"

# Function to output results and exit
output_results() {
    echo "LINT_STATUS=$LINT_STATUS"
    echo "OFFENSE_COUNT=$OFFENSE_COUNT"
    echo "FILES_CHECKED=$FILES_CHECKED"
    echo "CORRECTABLE_OFFENSES=$CORRECTABLE_OFFENSES"
}

# Function to parse RuboCop output for offense counts
parse_rubocop_output() {
    local rubocop_output="$1"
    local exit_code="$2"

    # Set basic status based on exit code
    if [ "$exit_code" -eq 0 ]; then
        LINT_STATUS="passed"
        OFFENSE_COUNT="0"
    elif [ "$exit_code" -eq 1 ]; then
        LINT_STATUS="failed"
    elif [ "$exit_code" -eq 2 ]; then
        LINT_STATUS="error"
        # RuboCop exit code 2 means there was an error (invalid config, etc.)
        return
    else
        LINT_STATUS="error"
        return
    fi

    # Try to extract detailed counts from output
    # Look for summary lines like "15 files inspected, 3 offenses detected, 1 offense auto-correctable"
    local summary_line
    summary_line=$(echo "$rubocop_output" | grep -E "files? inspected.*offenses? detected" | tail -1)

    if [ -n "$summary_line" ]; then
        # Extract files checked using grep and awk for more reliability
        if echo "$summary_line" | grep -q "files inspected"; then
            FILES_CHECKED=$(echo "$summary_line" | grep -o '[0-9]\+' | head -1)
        elif echo "$summary_line" | grep -q "file inspected"; then
            FILES_CHECKED="1"
        fi

        # Extract offense count - look for the pattern "X offenses detected"
        if echo "$summary_line" | grep -q "no offenses detected"; then
            OFFENSE_COUNT="0"
        elif echo "$summary_line" | grep -q "offenses detected"; then
            OFFENSE_COUNT=$(echo "$summary_line" | grep -o '[0-9]\+ offenses detected' | grep -o '^[0-9]\+')
        elif echo "$summary_line" | grep -q "offense detected"; then
            OFFENSE_COUNT="1"
        fi

        # Extract correctable offenses - look for the pattern "X offense(s) autocorrectable"
        if echo "$summary_line" | grep -q "autocorrectable"; then
            if echo "$summary_line" | grep -q "offenses autocorrectable"; then
                CORRECTABLE_OFFENSES=$(echo "$summary_line" | grep -o '[0-9]\+ offenses autocorrectable' | grep -o '^[0-9]\+')
            elif echo "$summary_line" | grep -q "offense autocorrectable"; then
                CORRECTABLE_OFFENSES=$(echo "$summary_line" | grep -o '[0-9]\+ offense autocorrectable' | grep -o '^[0-9]\+')
            fi
        fi
    fi

    # Fallback: count offense lines if summary parsing failed
    if [ "$OFFENSE_COUNT" = "unknown" ] && [ "$LINT_STATUS" = "failed" ]; then
        # Count lines that look like offense reports (file:line:column)
        local offense_lines
        offense_lines=$(echo "$rubocop_output" | grep -c "^[^[:space:]].*:[0-9]\+:[0-9]\+:" 2>/dev/null || echo "0")
        if [ "$offense_lines" -gt 0 ]; then
            OFFENSE_COUNT="$offense_lines"
        fi
    fi

    # Set defaults for unknown values
    if [ "$FILES_CHECKED" = "unknown" ]; then
        FILES_CHECKED="0"
    fi
    if [ "$CORRECTABLE_OFFENSES" = "unknown" ]; then
        CORRECTABLE_OFFENSES="0"
    fi
}

# Function to run RuboCop with error handling
run_rubocop() {
    local cmd_args=("$@")

    # Create temporary files for capturing output and error
    local temp_output
    local temp_error
    temp_output=$(mktemp)
    temp_error=$(mktemp)

    # Ensure cleanup on exit
    trap 'rm -f "$temp_output" "$temp_error"' EXIT

    # Run RuboCop and capture exit code
    local exit_code
    if "${cmd_args[@]}" >"$temp_output" 2>"$temp_error"; then
        exit_code=0
    else
        exit_code=$?
    fi

    # Read outputs
    local stdout_content
    local stderr_content
    stdout_content=$(cat "$temp_output")
    stderr_content=$(cat "$temp_error")

    # Output the actual RuboCop results to user (not our parsed variables)
    if [ -n "$stdout_content" ]; then
        echo "$stdout_content"
    fi
    if [ -n "$stderr_content" ]; then
        echo "$stderr_content" >&2
    fi

    # Parse the output for our summary variables
    parse_rubocop_output "$stdout_content" "$exit_code"

    return "$exit_code"
}

# Main execution function
main() {
    # Run detection first to get RuboCop configuration
    local detect_output
    if ! detect_output=$("$SCRIPT_DIR/detect.sh"); then
        echo "Error: Failed to run RuboCop detection" >&2
        output_results
        exit 1
    fi

    # Parse detection output
    local rubocop_available
    local rubocop_executable
    rubocop_available=$(echo "$detect_output" | grep "RUBOCOP_AVAILABLE=" | cut -d'=' -f2-)
    rubocop_executable=$(echo "$detect_output" | grep "RUBOCOP_EXECUTABLE=" | cut -d'=' -f2-)

    # Check if RuboCop is available
    if [ "$rubocop_available" != "true" ] || [ "$rubocop_executable" = "none" ]; then
        echo "Error: RuboCop is not available. Please install RuboCop:" >&2
        echo "  - Add to Gemfile: gem 'rubocop'" >&2
        echo "  - Or install globally: gem install rubocop" >&2
        LINT_STATUS="error"
        output_results
        exit 1
    fi

    # Split executable command (might be "bundle exec rubocop")
    local rubocop_cmd_parts
    read -ra rubocop_cmd_parts <<< "$rubocop_executable"

    # If no arguments provided, use current directory
    local files_to_check=("$@")
    if [ ${#files_to_check[@]} -eq 0 ]; then
        files_to_check=(".")
    fi

    # Run RuboCop
    echo "Running RuboCop..." >&2
    if run_rubocop "${rubocop_cmd_parts[@]}" "${files_to_check[@]}"; then
        # RuboCop succeeded (no offenses or only corrected offenses)
        if [ "$LINT_STATUS" = "error" ]; then
            LINT_STATUS="passed"
        fi
    else
        local rubocop_exit_code=$?
        if [ "$rubocop_exit_code" -eq 1 ]; then
            # Exit code 1 means offenses found (normal failure)
            if [ "$LINT_STATUS" = "error" ]; then
                LINT_STATUS="failed"
            fi
        else
            # Other exit codes indicate errors
            LINT_STATUS="error"
        fi
    fi

    # Output final results
    output_results
}

# Execute main function with all arguments
main "$@"