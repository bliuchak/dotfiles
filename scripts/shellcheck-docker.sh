#!/bin/bash

if [[ $# -eq 0 ]]; then
  echo "Usage: $0 <script.sh> [script2.sh ...]" >&2
  exit 1
fi

for script in "$@"; do
  if [[ ! -f "$script" ]]; then
    echo "Error: File '$script' not found" >&2
    continue
  fi

  dir=$(dirname "$(realpath "$script")")
  file=$(basename "$script")

  docker run --rm -v "$dir:/scripts:ro" peterdavehello/shellcheck:latest shellcheck "/scripts/$file"
done
