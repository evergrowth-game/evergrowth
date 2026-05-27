#!/bin/bash
# Converts modern 64x64 Minecraft/Minetest skins to the Classic 64x32 format.
# This strictly crops the top 32 pixels, preventing face/body misalignment.
# Requires 'ffmpeg' to be installed on your system.

# Create an output directory so we don't overwrite the originals
mkdir -p converted_64x32

# Loop through all PNG files in the current folder
for file in *.png; do
    # Skip if it's not a regular file
    [ -f "$file" ] || continue
    
    echo "Converting $file..."
    # -vf "crop=64:32:0:0" means: Output width 64, height 32, starting at x=0, y=0 (top left)
    ffmpeg -v error -i "$file" -vf "crop=64:32:0:0" -y "converted_64x32/$file"
done

echo "Conversion complete! Check the 'converted_64x32' folder."
