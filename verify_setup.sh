#!/usr/bin/env bash
set -euo pipefail

source "$HOME/miniconda3/etc/profile.d/conda.sh"
conda activate statistical-analysis

echo "== conda --version =="
conda --version

echo "== R --version =="
R --version | head -n 1

echo "== quarto check =="
quarto check

cat <<'QMD' > minimal.qmd
---
title: "Minimal"
format:
  html: default
  pdf: default
---

```{r}
summary(cars)
```
QMD

echo "== quarto render minimal.qmd =="
quarto render minimal.qmd

test -f minimal.html
test -f minimal.pdf
echo "Render outputs: minimal.html, minimal.pdf"
