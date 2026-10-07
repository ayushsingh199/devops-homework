#!/bin/bash
set -e
echo "================================="
echo "Starting Application Build"
echo "================================="
rm -rf build
mkdir -p build
cp app/calculator.py build/
cat > build/build-info.txt <<BUILDEOF
Application: Session 16 Calculator
Build Status: SUCCESS
Build Date: $(date)
BUILDEOF
echo ""
echo "Build files:"
ls -la build
echo ""
echo "Build completed successfully."
