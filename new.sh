ABS_OUTDIR="$(realpath "./extensions")"
mkdir -p "$ABS_OUTDIR"

echo "→ Creating ZIPs of installed extensions..."

for dir in ~/.local/share/gnome-shell/extensions/*; do
    if [[ -d "$dir" ]]; then
        UUID=$(basename "$dir")
        ZIP="$ABS_OUTDIR/$UUID.zip"
        echo "→ Packing $UUID"
        (cd "$dir" && zip -r "$ZIP" . > /dev/null)
    fi
done

echo "✔ All extensions zipped into ./extensions/"
