#!/bin/sh
# gen.sh - Ziglyph data and code generation script. This script will prepare all data and code for
# the Ziglyph library. Normally, users of the library need not run this.

if [ ! -d ./src/data/ucd ]; then
    echo "Creating directory structure..."
    mkdir -pv ./src/data/ucd
fi
cd ./src/data/ucd
if [ ! -f ./UCD.zip ]; then
    echo "Downloading Unicode Character Database..."
    wget -q https://www.unicode.org/Public/UCD/latest/ucd/UCD.zip
fi
echo "Extracting Unicode Character Database..."
unzip -qu UCD.zip
cd - > /dev/null
cd ./src/gen
echo "Generating Zig code..."
./gen
echo "Adding exports to src/components.zig..."
./comp_gen.sh
cd - > /dev/null
echo "Done!"
