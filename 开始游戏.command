#!/bin/zsh
set -e
project_dir="${0:A:h}"
for engine in /Applications/Godot.app/Contents/MacOS/Godot "$HOME/Applications/Godot.app/Contents/MacOS/Godot" "$HOME/Downloads/Godot.app/Contents/MacOS/Godot"; do
  if [[ -x "$engine" ]]; then
    exec "$engine" --path "$project_dir"
  fi
done
if command -v godot >/dev/null 2>&1; then
  exec godot --path "$project_dir"
fi
print '没有找到 Godot。请用 Godot 4.7 导入此目录的 project.godot，然后按 F5。'
read -k 1 '?按任意键关闭。'
