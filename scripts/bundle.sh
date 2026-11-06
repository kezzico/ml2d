#!/bin/bash
set -euo pipefail

# Create dist directory
rm -rf dist
mkdir -p dist

# Detect LuaJIT
if command -v luajit >/dev/null 2>&1; then
    echo "LuaJIT found. Compiling Lua files to bytecode..."
    compile_lua=true
else
    echo "LuaJIT not found. Copying Lua source files..."
    compile_lua=false
fi

# Bundle Lua files
while IFS= read -r -d '' lua_file; do
    relative_path="${lua_file#./}"
    output_file="dist/$relative_path"

    mkdir -p "$(dirname "$output_file")"

    if [ "$compile_lua" = true ]; then
        luajit -b "$lua_file" "$output_file"
    else
        cp "$lua_file" "$output_file"
    fi
done < <(
    find . \
        -type f \
        -name "*.lua" \
        -not -path "./android/*" \
        -not -path "./dist/*" \
        -print0
)

# Copy project assets
if [ -d "assets" ]; then
    cp -a assets dist/assets
fi

# Copy ml2d assets in their original location
if [ -d "ml2d/assets" ]; then
    mkdir -p dist/ml2d
    cp -a ml2d/assets dist/ml2d/assets
fi
