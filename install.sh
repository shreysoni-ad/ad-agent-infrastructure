#!/bin/bash
# AD Data Platform — Agent Infrastructure Installer
# Copies agent infrastructure to target workspace .kiro/ folder
set -e

TARGET="${1:-.}"

echo "Installing agent infrastructure to $TARGET/.kiro/"

mkdir -p "$TARGET/.kiro/hooks"
mkdir -p "$TARGET/.kiro/steering"
mkdir -p "$TARGET/.kiro/settings"

cp -r hooks/* "$TARGET/.kiro/hooks/" 2>/dev/null || echo "  (no hooks to copy)"
cp -r steering/* "$TARGET/.kiro/steering/" 2>/dev/null || echo "  (no steering to copy)"
cp -r settings/* "$TARGET/.kiro/settings/" 2>/dev/null || echo "  (no settings to copy)"

echo ""
echo "Done. Agent infrastructure installed to $TARGET/.kiro/"
echo ""
echo "Next steps:"
echo "  1. Start local services:  docker compose up -d"
echo "  2. Set AWS SSO profile:   aws sso login --profile <your-profile>"
echo "  3. Open workspace in Kiro IDE"
echo "  4. Ask agent: 'Seed the knowledge graph with core platform entities'"
