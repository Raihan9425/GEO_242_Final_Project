#!/bin/bash
cd "$(dirname "$0")/../data"

# Bahadurabad Water Level Station Data Preparation from the input file 
awk 'NR>1 {
    # split date
    split($1, d, "/");        # d[1]=month, d[2]=day, d[3]=year
    y = d[3]; m = d[1];

    # Picking the right water-level column
    wl = ""
    if (index($2, ":") > 0) {
        # there is a time column, so WL is in $3
        wl = $3
    } else {
        # old format, WL is in $2
        wl = $2
    }

    if (wl != "" && y >= 1962 && y <= 2017) {
        dec_year = y + (m - 1)/12.0
        printf "%.4f %s\n", dec_year, wl
    }
}' "Bahadurabad Water Level Data.txt" > bahadurabad_xy.dat


# Shirajganj Water Level Station Data Preparation from the input file
awk 'NR>1 {
    split($1, d, "/");
    y = d[3]; m = d[1];

    wl = ""
    if (index($2, ":") > 0) {
        wl = $3
    } else {
        wl = $2
    }

    if (wl != "" && y >= 1962 && y <= 2017) {
        dec_year = y + (m - 1)/12.0
        printf "%.4f %s\n", dec_year, wl
    }
}' "Shirajganj Water Level Data.txt" > sirajganj_xy.dat

