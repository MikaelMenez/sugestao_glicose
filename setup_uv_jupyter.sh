#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Script: setup_uv_jupyter.sh
# Descrição: Instala o uv (caso não esteja instalado), inicializa/configura o
#            ambiente virtual com ipykernel e registra o kernel no Jupyter.
# ==============================================================================

PROJECT_DIR="${1:-$(pwd)}"
KERNEL_NAME="${2:-$(basename "$PROJECT_DIR" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9_-' '-')}"
DISPLAY_NAME="${3:-Python (uv - $(basename "$PROJECT_DIR"))}"

echo "==> [1/4] Verificando instalação do uv..."
if ! command -v uv >/dev/null 2>&1; then
    echo "    uv não encontrado. Baixando e instalando via instalador oficial..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
else
    echo "    uv já instalado: $(uv --version)"
fi

if ! command -v uv >/dev/null 2>&1; then
    echo "Erro: Não foi possível localizar o binário 'uv' no PATH após a instalação." >&2
    exit 1
fi

echo "==> [2/4] Preparando diretório do projeto em: $PROJECT_DIR"
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

if [ ! -f "pyproject.toml" ]; then
    echo "    Inicializando novo projeto Python com 'uv init'..."
    uv init --no-workspace
else
    echo "    pyproject.toml já existente. Mantendo configuração atual."
fi

echo "==> [3/4] Adicionando ipykernel e sincronizando ambiente virtual (.venv)..."
uv add --dev ipykernel
uv sync

echo "==> [4/4] Registrando kernel '$DISPLAY_NAME' ($KERNEL_NAME) no Jupyter..."
.venv/bin/python -m ipykernel install --user --name="$KERNEL_NAME" --display-name="$DISPLAY_NAME"

echo ""
echo "Concluído com sucesso!"
echo "  - Diretório : $PROJECT_DIR"
echo "  - Kernel ID : $KERNEL_NAME"
echo "  - Nome UI   : $DISPLAY_NAME"
echo ""
echo "Para adicionar pacotes no futuro, use 'uv add <pacote>' no terminal ou '!uv add <pacote>' no notebook."
