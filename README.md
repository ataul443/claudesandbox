# Claude Sandbox

Run [Claude Code](https://docs.anthropic.com/en/docs/claude-code) inside isolated [zotavm](https://github.com/ataul443/zota) microVMs.

Claude runs with `--dangerously-skip-permissions` since the VM itself provides the sandbox boundary.

## Prerequisites

Install [zotavm](https://github.com/ataul443/zota):

```bash
curl -sSL https://zota.dev/install.sh | bash
```

## Install

```bash
curl -sSL https://raw.githubusercontent.com/ataul443/claudesandbox/main/install.sh | bash
```

Or clone and install locally:

```bash
git clone https://github.com/ataul443/claudesandbox.git
cd claudesandbox
./install.sh
```

## Usage

```bash
# Sandbox the current directory
claude-sandbox

# Sandbox a specific project
claude-sandbox -d /path/to/project

# Pass arguments to claude
claude-sandbox -- -p "fix the failing tests"

# Use more resources
claude-sandbox --cpus 4 --mem 4096

# Reuse an existing VM
claude-sandbox -i <vm-id>

# Destroy VM on exit (default: stop)
claude-sandbox --destroy
```

## Uninstall

```bash
curl -sSL https://raw.githubusercontent.com/ataul443/claudesandbox/main/install.sh | bash -s -- --uninstall
```

## License

MIT
