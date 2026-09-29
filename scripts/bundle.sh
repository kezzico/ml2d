# Create dist directory
rm -rf dist
mkdir -p dist

echo "bundle love game source code and assets..."
# Compile all Lua files with LuaJIT
find . -name "*.lua" -type f -not -path "./android/*" | while read lua_file; do
  mkdir -p "dist/$(dirname "$lua_file")"
  cp "$lua_file" "dist/$lua_file"
done

if [ -d "assets" ]; then
  cp -r assets "dist/assets"
fi

# Copy assets directory
cp -r assets dist/

pushd dist
zip app.love -r ./
popd dist