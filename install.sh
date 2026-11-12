#!/usr/bin/env bash
# Instala o forja criando um link em ~/.local/bin (ou no diretório passado).
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bindir="${1:-$HOME/.local/bin}"

mkdir -p "$bindir"
ln -sfn "$here/forja" "$bindir/forja"
chmod +x "$here/forja"
echo "✓ forja -> $bindir/forja"

case ":$PATH:" in
    *":$bindir:"*) ;;
    *) echo "! $bindir não está no PATH. Adicione ao ~/.zshrc:"
       echo "    export PATH=\"$bindir:\$PATH\"" ;;
esac

echo
echo "Autocompletar (zsh): adicione ao ~/.zshrc, antes do compinit:"
echo "    fpath=(\"$here/completions\" \$fpath)"
