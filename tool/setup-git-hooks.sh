#!/usr/bin/env sh
set -eu
chmod +x .githooks/pre-commit .githooks/commit-msg
git config core.hooksPath .githooks
echo "Admincraft Git hooks enabled for this checkout."
