#!/bin/bash
# Universal Multi-Distribution Python Environment Activation Script

VENV_DIR="venv"

if [[ ! -d "$VENV_DIR" ]]; then
    echo "Virtual environment not found. Run ./scripts/setup-python-env-universal.sh first"
    exit 1
fi

echo "Activating Python virtual environment..."
source "$VENV_DIR/bin/activate"

echo "Python environment activated!"
echo "Distribution: cachyos (arch family)"
echo "Python version: $(python --version)"
echo "Pip version: $(pip --version)"
echo ""
echo "Available tools:"
if command -v ansible &>/dev/null; then
    echo "  - ansible: $(ansible --version | head -1)"
fi
echo "  - terraform tools: $(pip list | grep -i terraform | wc -l) packages"
echo ""
echo "To deactivate, run: deactivate"
