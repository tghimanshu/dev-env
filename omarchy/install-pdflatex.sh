#!/usr/bin/env bash
set -euo pipefail

if ! command -v yay >/dev/null 2>&1; then
  echo "Error: yay is not installed." >&2
  exit 1
fi

PACKAGES=(
  texlive-basic
  texlive-latex
  texlive-latexrecommended
  texlive-latexextra
  texlive-fontsrecommended
  texlive-fontsextra
)

echo "Installing LaTeX packages: ${PACKAGES[*]}"
yay -S --noconfirm --needed "${PACKAGES[@]}"

if ! command -v pdflatex >/dev/null 2>&1; then
  echo "Error: pdflatex is still not available after installation." >&2
  exit 1
fi

echo "pdflatex installed at: $(command -v pdflatex)"
