set terminal postscript eps size 6,2 enhanced color font 'Helvetica,12'
set output 'heatmap-clang-queries-min.eps'

set palette defined (0 "white", 1 "red")

set key off

# set labels for x/y axis to block sizes"
XTICS="O0 O1 O2 O3 Ofast Og Os Oz"
YTICS="10 11 12 9"

set for [i=1:words(XTICS)] xtics ( word(XTICS,i) i-1 )
set for [i=1:words(YTICS)] ytics ( word(YTICS,i) i-1 )

# don't show color scale next to the heatmap
unset colorbox

set datafile separator ","

set multiplot layout 1, 2 rowsfirst

set title "x86-64, jit=off"

plot "clang-queries-min-off.data" matrix using 1:2:($3 == 0 ? "" : $3) with image, \
     "clang-queries-min-off.data" matrix using 1:2:($3 == 0 ? "" : sprintf("%g",$3)) with labels

set title "x86-64, jit=on"

plot "clang-queries-min-on.data" matrix using 1:2:($3 == 0 ? "" : $3) with image, \
     "clang-queries-min-on.data" matrix using 1:2:($3 == 0 ? "" : sprintf("%g",$3)) with labels
