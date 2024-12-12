# Git Status Check Script

`check_git_status.sh` is a Bash script designed to verify the status of multiple Git repositories within a workspace. It helps identify untracked files, unstaged changes, uncommitted commits, and branch differences with the remote repository.

---

## Features

The script analyzes each Git repository in a workspace and identifies:

1. **Untracked files**:
   - Files in the working directory that haven’t been added to Git (`git add` not run).

2. **Staged but uncommitted files**:
   - Files that were added with `git add` but not yet committed.

3. **Unstaged changes**:
   - Files with local modifications that haven’t been added to the staging area.

4. **Unpushed commits**:
   - Local commits that haven’t been pushed to the remote repository.

5. **Branches not in sync with the remote** (only when using the `fetch` option):
   - Detects if the local branch is ahead of or behind the remote branch.

<!-- 6. **Ignored files**:
   - Files listed in `.gitignore`. -->

---

## Usage

The script supports the following modes:

1. **Default Mode**:
   Checks repository status without updating remote references.

   ```bash
   ./check_git_status.sh
   ```

2. **Fetch Mode**:
   Runs `git fetch` for each repository before performing checks.

   ```bash
   ./check_git_status.sh fetch
   ```

3. **Debug Mode**:
   Outputs detailed information during execution, useful for troubleshooting.

   ```bash
   ./check_git_status.sh debug
   ```

4. **Fetch + Debug Mode**:
   Combines `fetch` and `debug` modes, updating remote references and providing detailed output.

   ```bash
   ./check_git_status.sh fetch-debug
   ```

---

## Output

### Summary Table

The script generates a summary table listing the repositories with detected changes. Example:

| Package Name      | Status                              | Behind Origin |
|--------------------|-------------------------------------|---------------|
| example_repo       | Modified but not added/committed   | No            |
| another_repo       | Branch not in sync with remote     | Yes           |




- **`Status`**: Indicates the repository's local changes.
- **`Behind Origin`**: Shows whether the local branch is behind the remote (only visible if `fetch` is used).

### When Everything is Clean

If no issues are detected, the script outputs:

```bash
All repositories are up-to-date.
```


---

## Installation

### Steps to Make the Script Accessible Globally

1. **Move the script to a directory in your PATH**:
   - To see directories in your PATH, run:
     ```bash
     echo $PATH
     ```
   - Common directories include `/usr/local/bin`. Move the script there:
     ```bash
     sudo mv check_git_status.sh /usr/local/bin/
     ```
   - Alternatively, create a `~/bin` directory:
     ```bash
     mkdir -p ~/bin
     mv check_git_status.sh ~/bin/
     ```

2. **Grant Execute Permissions**:
   ```bash
   chmod +x /usr/local/bin/check_git_status.sh
   ```
   If placed in `~/bin`:
   ```bash
   chmod +x ~/bin/check_git_status.sh
   ```

3. **Update PATH (if necessary)**:
   If `~/bin` is not in your PATH:
   - Add the following to `~/.bashrc` or `~/.zshrc`:
     ```bash
     export PATH=$PATH:~/bin
     ```
   - Reload the shell configuration:
     ```bash
     source ~/.bashrc
     ```

4. **Verify Installation**:
   You should now be able to run the script from any directory:
   ```bash
   check_git_status.sh
   ```

---

## Requirements

- **Git**: Ensure Git is installed on your system.
- **Bash**: The script is compatible with Bash.

---

## Contributing

If you have suggestions to improve the script or encounter any issues, feel free to submit a pull request or report a problem.

---

## Notes

- The script is designed to work in a workspace with a standard ROS structure (e.g., `src/`), but it can be adapted for other layouts.
- Without the `fetch` option, the script does not detect changes in branches that are not synced with the remote.

---
