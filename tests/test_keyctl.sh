#!/bin/bash
set -e

echo "Testing keyctl..."

# Check help
./keyctl --help
echo "PASS: --help works"

# Check exit code for unknown command
./keyctl unknown_command 2>/dev/null && exit 1 || echo "PASS: unknown command returns non-zero"

# Check subcommand help
./keyctl add --help
echo "PASS: add --help works"

./keyctl get --help
echo "PASS: get --help works"

./keyctl list --help
echo "PASS: list --help works"

./keyctl remove --help
echo "PASS: remove --help works"

./keyctl daemon --help
echo "PASS: daemon --help works"

echo "All tests passed!"