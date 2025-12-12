#!/usr/bin/env bash
# Compute annual max/min water level and plot using GMT 

set -euo pipefail
cd "$(dirname "$0")"

# Where to write outputs

FIGDIR="../figs"
OUTDIR="../data/derived"
mkdir -p "$FIGDIR" "$OUTDIR"

# input file in locations

SIRAJ_FILE="../data/Shirajganj Water Level Data.txt"
BAHA_FILE="../data/Bahadurabad Water Level Data.txt"

# Compute annual max/min
# Output columns: year  WL_max  WL_min
# Input has different formats so I had to write codes to accomodate different formats

annual_maxmin () {
  local INFILE="$1"
  local OUTFILE="$2"

  awk -F'[ \t]+' '
    BEGIN { OFS="\t" }

    # Skip any header line anywhere
    $0 ~ /Date/ && $0 ~ /Water/ { next }
    NF < 2 { next }

    {
      date = $1            # e.g., 1/1/2010
      wl   = $NF           

      gsub(/\r/, "", date)
      gsub(/\r/, "", wl)

      # WL must be numeric
      if (wl !~ /^-?[0-9]+(\.[0-9]+)?$/) next

      # year from date (MM/DD/YYYY)
      split(date, a, "/")
      if (length(a) < 3) next

      yr = a[3]
      gsub(/[^0-9]/, "", yr)   # just in case
      if (yr == "") next

      val = wl + 0.0

      if (!(yr in min) || val < min[yr]) min[yr] = val
      if (!(yr in max) || val > max[yr]) max[yr] = val
    }

    END {
      for (y in max) print y, max[y], min[y]
    }
  ' "$INFILE" | sort -n > "$OUTFILE"
}

# Plot one station (forced Y range)

plot_station () {
  local NAME="$1"
  local ANNUALFILE="$2"
  local YMIN_FIXED="$3"
  local YMAX_FIXED="$4"

  local MAXFILE="$OUTDIR/${NAME}_annual_max.dat"
  local MINFILE="$OUTDIR/${NAME}_annual_min.dat"
  local LEGFILE="$OUTDIR/legend_${NAME}.txt"

  # Split to two series: (year, value)
  awk '{print $1, $2}' "$ANNUALFILE" > "$MAXFILE"
  awk '{print $1, $3}' "$ANNUALFILE" > "$MINFILE"

  # X range from year column (pad by 1 year)
  read XMIN XMAX <<< "$(awk '
    BEGIN{ xmin=1e99; xmax=-1e99 }
    { if ($1 < xmin) xmin=$1; if ($1 > xmax) xmax=$1 }
    END{ print xmin, xmax }
  ' "$ANNUALFILE")"
  XMIN=$((XMIN-1))
  XMAX=$((XMAX+1))

  local OUTBASE="$FIGDIR/${NAME}_WL_maxmin"

  gmt begin "$OUTBASE" png ps
    gmt set MAP_FRAME_TYPE plain \
            FONT_TITLE 16p,Helvetica-Bold \
            FONT_LABEL 12p,Helvetica \
            FONT_ANNOT_PRIMARY 10p,Helvetica \
            MAP_GRID_PEN_PRIMARY 0.5p,gray50

    # Basemap + grid
    # Y axis forced to 5–25, major ticks every 5
    gmt basemap -R${XMIN}/${XMAX}/${YMIN_FIXED}/${YMAX_FIXED} -JX6.5i/3.2i \
      -Bxa10f5+l"Year" \
      -Bya5f1g5+l"Water Level (mPWD)" \
      -BWSen+t"Water Level at ${NAME} Station" \
      -Bga

    # Annual max: open circles
    gmt plot "$MAXFILE" -Sc0.12i -W1p,black -Gwhite

    # Annual min: open triangles
    gmt plot "$MINFILE" -St0.14i -W1p,black -Gwhite

    # Legend
    cat > "$LEGFILE" << EOF
S 0.15i c 0.12i white 1p,black 0.25i WL_Max
S 0.15i t 0.14i white 1p,black 0.25i WL_Min
EOF
    gmt legend "$LEGFILE" -DjTR+o0.15i -F+p1p+gwhite
  gmt end

  echo "Created:"
  echo "  ${OUTBASE}.png"
  echo "  ${OUTBASE}.ps"
}


# Run workflow

SIRAJ_ANNUAL="$OUTDIR/Sirajganj_annual_maxmin.txt"
BAHA_ANNUAL="$OUTDIR/Bahadurabad_annual_maxmin.txt"

echo "Computing annual max/min..."
annual_maxmin "$SIRAJ_FILE" "$SIRAJ_ANNUAL"
annual_maxmin "$BAHA_FILE"  "$BAHA_ANNUAL"

echo "Plotting..."
plot_station "Sirajganj"   "$SIRAJ_ANNUAL" 5 25
plot_station "Bahadurabad" "$BAHA_ANNUAL"  5 25

echo "Done."
