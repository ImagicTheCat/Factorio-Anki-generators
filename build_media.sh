#!/bin/bash

# copy factorio media to be used with Anki
# parameters: <factorio game directory path> <output directory (anki collection.media directory path)>
factorio_path=$1
out_path=$2

if [[ -z $factorio_path ]]; then
  printf "missing factorio game path"
  exit 1
fi

if [[ -z $out_path ]]; then
  printf "missing output path"
  exit 1
fi

cp "$factorio_path/data/core/graphics/slot.png" "$out_path/_factorio_core_graphics_slot.png"

find "$factorio_path/data/base/graphics/icons/" -name "*.png" | while IFS= read -r path; do
  file=$(basename "$path")
  cp "$path" "$out_path/factorio_base_graphics_icons_$file"
done
