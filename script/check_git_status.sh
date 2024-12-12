#!/bin/bash

# Pretty output functions
print_header() {
    echo -e "\n\e[1;34m=== $1 ===\e[0m"
}

print_table() {
    if [ ${#status[@]} -gt 0 ]; then
        if [ "$FETCH_ENABLED" == "true" ]; then
            echo -e "\n\e[1;34mGit Status Summary\e[0m"
            printf "%-30s | %-40s | %-20s\n" "Package Name" "Status" "Behind Origin"
            printf "%-30s | %-40s | %-20s\n" "------------------------------" "----------------------------------------" "--------------------"
            for key in "${!status[@]}"; do
                printf "%-30s | %-40s | %-20s\n" "$key" "${status[$key]}" "${behind[$key]}"
            done
        else
            echo -e "\n\e[1;34mGit Status Summary\e[0m"
            printf "%-30s | %-40s\n" "Package Name" "Status"
            printf "%-30s | %-40s\n" "------------------------------" "----------------------------------------"
            for key in "${!status[@]}"; do
                printf "%-30s | %-40s\n" "$key" "${status[$key]}"
            done
        fi
    else
        echo -e "\e[1;32mAll repositories are up-to-date.\e[0m"
    fi
}

# Declare associative arrays to hold status and behind info
declare -A status
declare -A behind

# Function to check the Git status of a package
check_git_status() {
    local dir=$1
    local pkg_name=$(basename "$dir")
    local fetch_enabled=$2
    local debug_enabled=$3

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
        if git -C "$dir" status --porcelain | grep -q '^??'; then
            status[$pkg_name]="Modified but not added/committed"
        fi
        if ! git -C "$dir" diff --cached --quiet; then
            status[$pkg_name]="Staged but not committed"
        fi
        if ! git -C "$dir" diff --quiet; then
            status[$pkg_name]="Modified but not added/committed"
        fi
        if [ "$fetch_enabled" == "true" ]; then
            if ! git -C "$dir" diff --quiet origin/$(git -C "$dir" branch --show-current); then
                status[$pkg_name]="Branch not in sync with remote"
            fi
        fi
        local branch=$(git -C "$dir" branch --show-current)
        if [ -n "$(git -C "$dir" log origin/$branch..HEAD 2>/dev/null)" ]; then
            status[$pkg_name]="Committed but not pushed"
        fi
    fi
}

# Main script starts here
print_header "Checking Git Status of Packages"

FETCH_ENABLED="false"
DEBUG_ENABLED="false"

if [ "$1" == "fetch" ]; then
    FETCH_ENABLED="true"
    echo -e "\e[1;32mFetch enabled: fetching remote status for each repository.\e[0m"
elif [ "$1" == "debug" ]; then
    DEBUG_ENABLED="true"
    echo -e "\e[1;33mDebug mode enabled: printing debug information.\e[0m"
elif [ "$1" == "fetch-debug" ]; then
    FETCH_ENABLED="true"
    DEBUG_ENABLED="true"
    echo -e "\e[1;33mFetch and Debug mode enabled: fetching and printing debug information.\e[0m"
fi

if [ -d "src" ]; then
    WORKSPACE_DIR=$(pwd)/src
else
    WORKSPACE_DIR=$(pwd)
fi

if [ ! -d "$WORKSPACE_DIR" ]; then
    echo -e "\e[1;31m[ERROR]\e[0m Could not find a valid workspace directory."
    exit 1
fi

for dir in "$WORKSPACE_DIR"/*; do
    if [ -d "$dir" ]; then
        check_git_status "$dir" "$FETCH_ENABLED" "$DEBUG_ENABLED"
    fi
done

print_table
