#!/bin/bash

# Pretty output functions
# Print header section with a title in blue
print_header() {
    echo -e "\n\e[1;34m=== $1 ===\e[0m"
}

# Print the list of workspaces being evaluated
print_workspace_list() {
    echo -e "\n\e[1;34mWorkspaces being evaluated:\e[0m"
    for base_dir in "${WORKSPACE_DIRS[@]}"; do
        echo -e "\e[1;32m$base_dir\e[0m"
    done
}

print_table() {
    if [ ${#status[@]} -gt 0 ]; then
        if [ "$FETCH_ENABLED" == "true" ]; then
            echo -e "\n\e[1;34mGit Status Summary\e[0m"
            printf "%-30s | %-40s | %-20s | %-60s\n" "Package Name" "Status" "Behind Origin" "Repository Path"
            printf "%-30s | %-40s | %-20s | %-60s\n" "------------------------------" "----------------------------------------" "--------------------" "------------------------------------------------------------"
            for key in "${!status[@]}"; do
                # Print the package name, status, behind status, and full repo path
                printf "%-30s | %-40s | %-20s | %-60s\n" "$key" "${status[$key]}" "${behind[$key]}" "${repo_paths[$key]}"
            done
        else
            echo -e "\n\e[1;34mGit Status Summary\e[0m"
            printf "%-30s | %-40s | %-60s\n" "Package Name" "Status" "Repository Path"
            printf "%-30s | %-40s | %-60s\n" "------------------------------" "----------------------------------------" "------------------------------------------------------------"
            for key in "${!status[@]}"; do
                # Print the package name, status, and full repo path
                printf "%-30s | %-40s | %-60s\n" "$key" "${status[$key]}" "${repo_paths[$key]}"
            done
        fi
    else
        echo -e "\e[1;32mAll repositories are up-to-date.\e[0m"
    fi
}

# Declare associative arrays to hold status, behind info, and repo path
declare -A status
declare -A behind
declare -A repo_paths

# Function to check the Git status of a package
check_git_status() {
    local dir=$1
    local pkg_name=$(basename "$dir")
    local fetch_enabled=$2
    local debug_enabled=$3

    # Store the full path to the repository in the associative array
    repo_paths[$pkg_name]="$dir"

    if [ "$debug_enabled" == "true" ]; then
        echo -e "\n\e[1;33m[DEBUG] Checking package: $pkg_name\e[0m"
        echo -e "\e[1;33m[DEBUG] Directory: $dir\e[0m"
    fi

    if [ -d "$dir/.git" ]; then
        if [ "$fetch_enabled" == "true" ];then
            git -C "$dir" fetch > /dev/null 2>&1
            if [ "$debug_enabled" == "true" ]; then
                echo -e "\e[1;33m[DEBUG] Fetch completed for $pkg_name\e[0m"
            fi
        fi
        # Check if there are untracked files (??) in the status
        if git -C "$dir" status --porcelain | grep -q '^??'; then
            status[$pkg_name]="Modified but not added/committed"
        fi
        # Check if there are staged but not committed changes
        if ! git -C "$dir" diff --cached --quiet; then
            status[$pkg_name]="Staged but not committed"
        fi
        # Check if there are unstaged but modified changes
        if ! git -C "$dir" diff --quiet; then
            status[$pkg_name]="Modified but not added/committed"
        fi
        # Check if the repository is behind the origin branch (if fetch is enabled)
        if [ "$fetch_enabled" == "true" ]; then
            local branch=$(git -C "$dir" branch --show-current)
            if ! git -C "$dir" diff --quiet origin/$branch..HEAD; then
                status[$pkg_name]="Branch not in sync with remote"
                behind[$pkg_name]="Yes"
            else
                behind[$pkg_name]="No"
            fi
        fi
        # Check if there are commits that have not been pushed
        local branch=$(git -C "$dir" branch --show-current)
        if [ -n "$(git -C "$dir" log origin/$branch..HEAD 2>/dev/null)" ]; then
            status[$pkg_name]="Committed but not pushed"
        fi
    fi
}

# Main script starts here
print_header "Checking Git Status of Packages"

# Default settings for fetch and debug
FETCH_ENABLED="false"
DEBUG_ENABLED="false"

# Parse arguments
for arg in "$@"; do
    case $arg in
        fetch)
            FETCH_ENABLED="true"
            echo -e "\e[1;32mFetch enabled: fetching remote status for each repository.\e[0m"
            shift
            ;;
        debug)
            DEBUG_ENABLED="true"
            echo -e "\e[1;33mDebug mode enabled: printing debug information.\e[0m"
            shift
            ;;
        fetch-debug)
            FETCH_ENABLED="true"
            DEBUG_ENABLED="true"
            echo -e "\e[1;33mFetch and Debug mode enabled: fetching and printing debug information.\e[0m"
            shift
            ;;
        *)
            # Collect valid directory paths
            if [ -d "$arg" ]; then
                WORKSPACE_DIRS+=("$arg")
            else
                echo -e "\e[1;31m[ERROR]\e[0m $arg is not a valid directory."
            fi
            ;;
    esac
done

# If no directories were passed, use the current directory
if [ ${#WORKSPACE_DIRS[@]} -eq 0 ]; then
    WORKSPACE_DIRS=("$PWD")
fi

# Check if directories exist
if [ ${#WORKSPACE_DIRS[@]} -eq 0 ]; then
    echo -e "\e[1;31m[ERROR]\e[0m No valid directories provided."
    exit 1
fi

# Print the list of workspaces being evaluated
print_workspace_list

# For each directory passed or current directory, search for Git repositories
for base_dir in "${WORKSPACE_DIRS[@]}"; do
    if [ -d "$base_dir" ]; then
        # Use `find` to search for Git repositories in each specified directory
        for dir in $(find "$base_dir" -type d -name ".git" -exec dirname {} \;); do
            check_git_status "$dir" "$FETCH_ENABLED" "$DEBUG_ENABLED"
        done
    else
        echo -e "\e[1;31m[ERROR]\e[0m Directory $base_dir does not exist."
    fi
done

# Print the final status table with the repository paths
print_table
