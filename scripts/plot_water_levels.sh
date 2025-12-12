#!/bin/bash
set -euo pipefail

# Input file and directory
PROJ_DIR="$(cd "$(dirname "$0")/.." && pwd)"
FIG_DIR="$PROJ_DIR/figs"
mkdir -p "$FIG_DIR"

BAHA_IN="$PROJ_DIR/data/bahadurabad_xy.dat"
SIRA_IN="$PROJ_DIR/data/sirajganj_xy.dat"

BAHA_CLEAN="$FIG_DIR/bahadurabad_xy_clean.dat"
SIRA_CLEAN="$FIG_DIR/sirajganj_xy_clean.dat"

# Keep only lines with 2 numeric columns (x y). Accept whitespace or commas as separators.
clean_xy () {
  local INFILE="$1"
  local OUTFILE="$2"
  awk 'BEGIN{FS="[,\t ]+"} NF>=2 {x=$1; y=$2; gsub(/[^0-9eE.+-]/,"",x); gsub(/[^0-9eE.+-]/,"",y); if (x != "" && y != "" && x+0==x && y+0==y) print x, y}' "$INFILE" > "$OUTFILE"
}

clean_xy "$BAHA_IN" "$BAHA_CLEAN"
clean_xy "$SIRA_IN" "$SIRA_CLEAN"

n1=$(wc -l < "$BAHA_CLEAN" | tr -d ' ')
n2=$(wc -l < "$SIRA_CLEAN" | tr -d ' ')
echo "Cleaned files written:"
echo "  $BAHA_CLEAN  (kept $n1 lines)"
echo "  $SIRA_CLEAN  (kept $n2 lines)"

if [ "$n1" -eq 0 ] || [ "$n2" -eq 0 ]; then
  echo "ERROR: One of the cleaned files is empty." #I included this because sometimes I faced trouble
  exit 1
fi

# Plot region 
R="-R1962/2017/5/22"
J="-JX18c/8c"

OUTBASE="$FIG_DIR/jamuna_WL_1962_2017"

gmt begin "$OUTBASE" png
  gmt set MAP_FRAME_TYPE=plain FONT_TITLE=16p FONT_LABEL=12p FONT_ANNOT_PRIMARY=11p PS_CONVERT=A
  gmt basemap $R $J -Bxa5f1g5+l"Year" -Bya5f1g5+l"Water level (m, PWD)" -BWSen+t"Jamuna water level (1962-2017)"
  gmt plot "$BAHA_CLEAN" $R $J -W1p,blue
  gmt plot "$SIRA_CLEAN" $R $J -W1p,red
  printf "%s\n" "S 0.25c - 0.8c blue 1p 0.8c Bahadurabad" "S 0.25c - 0.8c red 1p 0.8c Sirajganj" | gmt legend -DjTR+o0.2c -F+p1p+gwhite
gmt end

# Write PS and PNG.
gmt begin "$OUTBASE" ps
  gmt set MAP_FRAME_TYPE=plain FONT_TITLE=16p FONT_LABEL=12p FONT_ANNOT_PRIMARY=11p PS_MEDIA=A4 PS_CONVERT=A
  gmt basemap $R $J -Bxa5f1g5+l"Year" -Bya5f1g5+l"Water level (m, PWD)" -BWSen+t"Jamuna water level (1962-2017)"
  gmt plot "$BAHA_CLEAN" $R $J -W1p,blue
  gmt plot "$SIRA_CLEAN" $R $J -W1p,red
  printf "%s\n" "S 0.25c - 0.8c blue 1p 0.8c Bahadurabad" "S 0.25c - 0.8c red 1p 0.8c Sirajganj" | gmt legend -DjTR+o0.2c -F+p1p+gwhite
gmt end

echo "Created:"
echo "  $OUTBASE.png"
echo "  $OUTBASE.ps"
