# shellcheck shell=bash

{ # this ensures the entire script is downloaded #
  REPL_LATEST_VERSION="v0.3.0"
  INSTALL_DIR="$HOME/.repl"

  repl_check_git() {
    command -v git >/dev/null 2>&1 || {
      printf "Error: git is not installed\n"
      exit 1
    }
  }

  repl_add_to_path() {
    local source_str="\\n# Add REPL to PATH\nexport PATH=\"\$HOME/.repl-install-test:\$PATH\"\\n"

    if [ -e "$HOME/.bashrc" ]; then
      command printf "${source_str}" >> "$HOME/.bashrc"
    fi
    if [ -e "$HOME/.zshrc" ]; then
      command printf "${source_str}" >> "$HOME/.zshrc"
    fi
  }

  repl_install_from_git() {
    local repl_source="https://github.com/DamianRivas/REPL.git"

    printf "Cloning REPL...\n"
    printf "=> Downloading REPL from git to '%s/'\n" "$INSTALL_DIR"

    if [ "$(ls -A "${INSTALL_DIR}")" ]; then
      command git init "${INSTALL_DIR}" || {
        printf >&2 'Failed to initialize REPL repo. Please report this!\n'
        exit 2
      }
      command git --git-dir="${INSTALL_DIR}/.git" remote add origin "$repl_source" 2> /dev/null || \
        command git --git-dir="${INSTALL_DIR}/.git" remote set-url origin "$repl_source" || {
        printf >&2 'Failed to add remote "origin" (or set the URL). Please report this!\n'
        exit 2
      }
      command git --git-dir="${INSTALL_DIR}/.git" fetch origin tag "$REPL_LATEST_VERSION" --depth=1 || {
        printf >&2 'Failed to fetch origin with tags. Please report this!\n'
        exit 2
      }
    else
      command git -c advice.detachedHead=false clone "$repl_source" -b "$REPL_LATEST_VERSION" --depth=1 "${INSTALL_DIR}" || {
        printf >&2 'Failed to clone REPL repo. Please report this!\n'
        exit 2
      }
    fi

    command git -c advice.detachedHead=false --git-dir="$INSTALL_DIR"/.git --work-tree="$INSTALL_DIR" checkout -f --quiet "$REPL_LATEST_VERSION"

    # Delete the master branch
    if [ ! -z "$(command git --git-dir="$INSTALL_DIR"/.git --work-tree="$INSTALL_DIR" show-ref refs/heads/master)" ]; then
      if command git --git-dir="$INSTALL_DIR"/.git --work-tree="$INSTALL_DIR" branch --quiet 2>/dev/null; then
        command git --git-dir="$INSTALL_DIR"/.git --work-tree="$INSTALL_DIR" branch --quiet -D master >/dev/null 2>&1
      else
        printf >&2 "Your version of git is out of date. Please update it!\n"
        command git --git-dir="$INSTALL_DIR"/.git --work-tree="$INSTALL_DIR" branch -D master >/dev/null 2>&1
      fi
    fi

    # git reflog
    printf "=> Compressing and cleaning up git repository\n"
    if ! command git --git-dir="$INSTALL_DIR"/.git --work-tree="$INSTALL_DIR" reflog expire --expire=now --all; then
      printf >&2 "Your version of git is out of date. Please update it!\n"
    fi
    #git gc
    if ! command git --git-dir="$INSTALL_DIR"/.git --work-tree="$INSTALL_DIR" gc --auto --aggressive --prune=now ; then
      printf >&2 "Your version of git is out of date. Please update it!\n"
    fi

    return
  }

  main() {
    mkdir -p "$INSTALL_DIR" || {
      printf "Error: Failed to create install directory in '%s'. Check permissions.\n" "$HOME"
      exit 1
    }

    repl_check_git
    repl_install_from_git
    if cd "$HOME" && ! (repl status) > /dev/null 2>&1; then
      repl_add_to_path
    fi

    printf '   ___  _______  __  \n'
    printf '  / _ \/ __/ _ \/ /  \n'
    printf ' / , _/ _// ___/ /__ \n'
    printf '/_/|_/___/_/  /____/ \n'
    printf '\n'
    printf 'Congratulations! REPL is now installed.\n'
    # shellcheck disable=SC2016
    printf 'Run `repl status` to ensure it installed properly\n'
    printf 'If this is the first time you run repl, output will be similar to:\n'
    printf '    repl: No current repl\n'
    printf 'You may have to restart your shell for PATH changes to take effect.\n'
    printf '\n'
    printf 'Thank you for using REPL!'
    printf '\n'
  }

  main

} # this ensures the entire script is downloaded #
