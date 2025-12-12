#!/usr/bin/env bash
set -euo pipefail

# Setting the input and directory file
cd "$(dirname "$0")"

OUT_BASE="../figs/jamuna_stations"
OUT_PS="${OUT_BASE}.ps"
OUT_PNG="${OUT_BASE}.png"
mkdir -p ../figs

# Station coordinates (lon, lat)
BAHA_LON=89.73464
BAHA_LAT=25.13028
SIRA_LON=89.71961
SIRA_LAT=24.46847

# Map region and projection
REGION="88/93/20/26.5"
PROJ="M90/12c"

# Remove old output if it exists
rm -f "$OUT_PS"

# Plot coastline and political boundaries
# -A1000 removes very small polygons to reduce clutter
gmt pscoast -R$REGION -J$PROJ -P -Df -A1000 -W0.25p -N1/0.25p -Bx1f0.5 -By1f0.5 -BWSne -K > "$OUT_PS"

# Plot station locations (red circles)
cat << EOF | gmt psxy -R$REGION -J$PROJ -Sc0.12i -Gred -W0.5p,black -O -K >> "$OUT_PS"
$BAHA_LON $BAHA_LAT
$SIRA_LON $SIRA_LAT
EOF

# Add station labels
cat << EOF | gmt pstext -R$REGION -J$PROJ -F+f10p,Helvetica,black+jML -D0.06i/0i -O -K >> "$OUT_PS"
$BAHA_LON $BAHA_LAT Bahadurabad
$SIRA_LON $SIRA_LAT Sirajganj
EOF

# End the PostScript plot
gmt psxy -R$REGION -J$PROJ -T -O >> "$OUT_PS"

# Convert PS to PNG
gmt psconvert "$OUT_PS" -A -Tg -P -E600 -F"$OUT_BASE"

echo "Created map files:"
echo "  $OUT_PS"
echo "  $OUT_PNG"
