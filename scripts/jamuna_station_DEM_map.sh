#!/usr/bin/env bash
# Makes two small DEM maps (GeoTIFF) around Sirajganj and Bahadurabad stations.


set -euo pipefail

# Run relative to the folder where this script lives
cd "$(dirname "$0")"

# Input DEM 
DEM="../DEM/Sob DEM.tif"

# Temporary color palette table (CPT) made from each cropped DEM
CPT="dem_tmp.cpt"

# Output folder
FIGDIR="../figs"
mkdir -p "$FIGDIR"

# Function: make one station DEM map
# args:
#   1) NAME    (label text)
#   2) LON     (decimal degrees)
#   3) LAT     (decimal degrees)
#   4) REGION  (lonmin/lonmax/latmin/latmax)
#   5) PS      
#   6) OUTBASE (full output base path without extension; GMT will create .png)
make_station_map () {
    local NAME="$1"
    local LON="$2"
    local LAT="$3"
    local REGION="$4"
    local PS="$5"
    local OUTBASE="$6"

    # Cropped DEM output (GMT grid)
    local SUBGRD="../DEM/${NAME}_sub.grd"

    # Temporary station file for psxy/pstext
    local STATION_FILE="station_${NAME}.dat"

    echo "Making DEM map for $NAME ..."

    # 1) Crop DEM around the station
    gmt grdcut "$DEM" -G"$SUBGRD" -R$REGION

    # 2) Build a discrete (classified) color palette from the cropped grid
   
    gmt grd2cpt "$SUBGRD" -Cdem2 -Z > "$CPT"

    # 3) Start PS and draw map frame (Mercator 4 inches wide)
    gmt psbasemap -R$REGION -JM4i -Bxa0.05f0.025 -Bya0.05f0.025 -BWSne -P -K > "$PS"

    # 4) Plot the DEM
    
    gmt grdimage "$SUBGRD" -R$REGION -JM4i -C"$CPT" -I+d -O -K >> "$PS"

    # 5) Add coastline/boundary outline on top for context
  
    gmt pscoast -R$REGION -JM4i -W0.25p -Df -O -K >> "$PS"

    # 6) Write station lon/lat name to a file
    cat << EOF > "$STATION_FILE"
$LON $LAT $NAME
EOF

    # 7) Plot station marker (small red circle)
    gmt psxy "$STATION_FILE" -R$REGION -JM4i -Sc0.12i -Gred -W0.5p,black -O -K >> "$PS"

    # 8) Plot station label
    gmt pstext "$STATION_FILE" -R$REGION -JM4i -F+f10p,Helvetica,black+jML -D0.06i/0i -O -K >> "$PS"

    # 9) Colorbar 
    gmt psscale -R$REGION -JM4i -C"$CPT" -DjBR+o0.3i/0.2i+w2.5i/0.15i -Baf+l"Elevation (m)" -O >> "$PS"

    # 10) Convert PS to PNG
    #     -F uses base name (no extension). GMT will add .png.
    gmt psconvert "$PS" -A -P -Tg -E300 -F"$OUTBASE"

    echo "  -> $PS"
    echo "  -> ${OUTBASE}.png"
}

# Sirajganj station (small window around coordinates)
make_station_map "Sirajganj" 89.71961 24.46847 "89.60/89.84/24.34/24.60" "$FIGDIR/jamuna_Sirajganj_dem.ps" "$FIGDIR/jamuna_Sirajganj_dem"

# Bahadurabad station (small window around coordinates)
make_station_map "Bahadurabad" 89.73464 25.13028 "89.60/89.84/25.00/25.26" "$FIGDIR/jamuna_Bahadurabad_dem.ps" "$FIGDIR/jamuna_Bahadurabad_dem"

# Cleanup temporary files
rm -f "$CPT" station_*.dat

echo "Done."
