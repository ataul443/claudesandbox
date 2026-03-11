#!/usr/bin/env bash
# Claude Sandbox installer
#
# Usage:
#   curl -sSL https://raw.githubusercontent.com/ataul443/claudesandbox/main/install.sh | bash
#
# Options:
#   --uninstall   Remove claude-sandbox
#   --help        Show this help message
#
# Prerequisites:
#   zotavm must be installed. Install it with:
#     curl -sSL https://zota.dev/install.sh | bash

set -euo pipefail

INSTALL_DIR="${HOME}/.local/bin"
REPO_URL="https://raw.githubusercontent.com/ataul443/claudesandbox/main"
UNINSTALL=false

# Colors (disabled if not a terminal)
if [ -t 1 ]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[0;33m'
  BLUE='\033[0;34m'
  BOLD='\033[1m'
  NC='\033[0m'
else
  RED='' GREEN='' YELLOW='' BLUE='' BOLD='' NC=''
fi

info()    { echo -e "${BLUE}info:${NC} $1"; }
success() { echo -e "${GREEN}success:${NC} $1"; }
warn()    { echo -e "${YELLOW}warning:${NC} $1"; }
error()   { echo -e "${RED}error:${NC} $1" >&2; }

usage() {
  cat <<EOF
Claude Sandbox installer

Installs claude-sandbox, a wrapper that runs Claude Code inside
isolated zotavm microVMs.

Usage:
    curl -sSL $REPO_URL/install.sh | bash

Options:
    --uninstall   Remove claude-sandbox
    --help        Show this help message

Prerequisites:
    zotavm must be installed first:
      curl -sSL https://zota.dev/install.sh | bash
EOF
}

check_zotavm() {
  if command -v zotavm &>/dev/null; then
    info "Found zotavm at $(command -v zotavm)"
    return 0
  fi

  # Check common install location
  if [[ -x "${HOME}/.zota/bin/zotavm" ]]; then
    info "Found zotavm at ${HOME}/.zota/bin/zotavm"
    return 0
  fi

  error "zotavm is not installed."
  echo ""
  echo "  Install it first with:"
  echo ""
  echo "    curl -sSL https://zota.dev/install.sh | bash"
  echo ""
  exit 1
}

download() {
  local url="$1" output="$2"
  if command -v curl &>/dev/null; then
    curl -fsSL "$url" -o "$output"
  elif command -v wget &>/dev/null; then
    wget -q "$url" -O "$output"
  else
    error "curl or wget is required"
    exit 1
  fi
}

install() {
  echo ""
  echo -e "${BOLD}Claude Sandbox installer${NC}"
  echo ""

  check_zotavm

  mkdir -p "$INSTALL_DIR"

  # Check if running from local clone or remote
  local script_dir
  script_dir="$(cd "$(dirname "$0")" && pwd)"

  if [[ -f "$script_dir/bin/claude-sandbox" ]]; then
    info "Installing from local source..."
    cp "$script_dir/bin/claude-sandbox" "$INSTALL_DIR/claude-sandbox"
  else
    info "Downloading claude-sandbox..."
    download "$REPO_URL/bin/claude-sandbox" "$INSTALL_DIR/claude-sandbox"
  fi

  chmod +x "$INSTALL_DIR/claude-sandbox"

  # Ensure INSTALL_DIR is in PATH
  if ! echo "$PATH" | tr ':' '\n' | grep -qx "$INSTALL_DIR"; then
    local profile=""
    case "$SHELL" in
      */zsh)  profile="$HOME/.zshrc" ;;
      */bash)
        [[ -f "$HOME/.bash_profile" ]] && profile="$HOME/.bash_profile" || profile="$HOME/.bashrc"
        ;;
      */fish)
        profile="$HOME/.config/fish/config.fish"
        ;;
      *) profile="$HOME/.profile" ;;
    esac

    if [[ -n "$profile" ]] && ! grep -q "$INSTALL_DIR" "$profile" 2>/dev/null; then
      info "Adding $INSTALL_DIR to PATH in $profile"
      if [[ "$SHELL" == */fish ]]; then
        printf '\n# claude-sandbox\nset -gx PATH %s $PATH\n' "$INSTALL_DIR" >> "$profile"
      else
        printf '\n# claude-sandbox\nexport PATH="%s:$PATH"\n' "$INSTALL_DIR" >> "$profile"
      fi
      warn "Run 'source $profile' or open a new terminal to use claude-sandbox."
    fi
  fi

  echo ""
  success "claude-sandbox installed to $INSTALL_DIR/claude-sandbox"
  echo ""
  echo "  Usage:"
  echo "    claude-sandbox                    # sandbox current directory"
  echo "    claude-sandbox -d /path/to/proj   # sandbox a specific directory"
  echo "    claude-sandbox --destroy          # destroy VM on exit"
  echo "    claude-sandbox -- -p 'fix bugs'   # pass args to claude"
  echo ""
}

uninstall() {
  echo ""
  echo -e "${BOLD}Uninstalling claude-sandbox${NC}"
  echo ""

  if [[ -f "$INSTALL_DIR/claude-sandbox" ]]; then
    rm -f "$INSTALL_DIR/claude-sandbox"
    success "Removed $INSTALL_DIR/claude-sandbox"
  else
    warn "claude-sandbox not found at $INSTALL_DIR/claude-sandbox"
  fi

  warn "You may want to remove the PATH entry from your shell profile."
  echo ""
}

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --uninstall)  UNINSTALL=true; shift ;;
    --help|-h)    usage; exit 0 ;;
    *)            error "Unknown option: $1"; usage; exit 1 ;;
  esac
done

if [[ "$UNINSTALL" == true ]]; then
  uninstall
else
  install
fi
