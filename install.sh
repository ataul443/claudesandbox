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
# zotavm is installed automatically if not already present.

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

zotavm is installed automatically if not already present.
EOF
}

ZOTA_INSTALL_URL="https://raw.githubusercontent.com/ataul443/zota/dev/install.sh"

ensure_zotavm() {
  if command -v zotavm &>/dev/null || [[ -x "${HOME}/.zota/bin/zotavm" ]]; then
    return 0
  fi

  info "Installing dependencies..."

  if command -v curl &>/dev/null; then
    bash <(curl -fsSL "$ZOTA_INSTALL_URL") &>/dev/null
  elif command -v wget &>/dev/null; then
    bash <(wget -qO- "$ZOTA_INSTALL_URL") &>/dev/null
  else
    error "curl or wget is required"
    exit 1
  fi

  # Verify it installed
  if ! command -v zotavm &>/dev/null && [[ ! -x "${HOME}/.zota/bin/zotavm" ]]; then
    error "Dependency installation failed"
    exit 1
  fi
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

  ensure_zotavm

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

  # Remove the binary
  if [[ -f "$INSTALL_DIR/claude-sandbox" ]]; then
    rm -f "$INSTALL_DIR/claude-sandbox"
    success "Removed $INSTALL_DIR/claude-sandbox"
  else
    warn "claude-sandbox not found at $INSTALL_DIR/claude-sandbox"
  fi

  # Remove PATH entry from shell profiles
  local profiles=(
    "$HOME/.zshrc"
    "$HOME/.bashrc"
    "$HOME/.bash_profile"
    "$HOME/.profile"
    "$HOME/.config/fish/config.fish"
  )
  for profile in "${profiles[@]}"; do
    if [[ -f "$profile" ]] && grep -q "# claude-sandbox" "$profile" 2>/dev/null; then
      # Remove the claude-sandbox block (comment + export/set line)
      sed -i.bak '/# claude-sandbox/,+1d' "$profile" && rm -f "${profile}.bak"
      # Remove any leftover blank lines at end of file
      sed -i.bak -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$profile" && rm -f "${profile}.bak"
      success "Removed PATH entry from $profile"
    fi
  done

  # Remove INSTALL_DIR if empty
  if [[ -d "$INSTALL_DIR" ]] && [[ -z "$(ls -A "$INSTALL_DIR" 2>/dev/null)" ]]; then
    rmdir "$INSTALL_DIR"
    success "Removed empty directory $INSTALL_DIR"
  fi

  # Uninstall zotavm
  if command -v zotavm &>/dev/null || [[ -x "${HOME}/.zota/bin/zotavm" ]]; then
    info "Removing dependencies..."
    if command -v curl &>/dev/null; then
      bash <(curl -fsSL "$ZOTA_INSTALL_URL") --uninstall &>/dev/null
    elif command -v wget &>/dev/null; then
      bash <(wget -qO- "$ZOTA_INSTALL_URL") --uninstall &>/dev/null
    fi
  fi

  echo ""
  success "claude-sandbox has been fully uninstalled."
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
