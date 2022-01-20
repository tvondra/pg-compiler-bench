set terminal postscript eps size 6,4 enhanced color font 'Helvetica,12'
set output 'heatmap-clang-load.eps'

set palette defined (0 "white", 1 "red")

set key off

# set labels for x/y axis to block sizes"
XTICS="O0 O1 O2 O3 Og Os Oz"
YTICS="10 11 12 9"

set for [i=1:words(XTICS)] xtics ( word(XTICS,i) i-1 )
set for [i=1:words(YTICS)] ytics ( word(YTICS,i) i-1 )

# don't show color scale next to the heatmap
unset colorbox

set datafile separator ","

set title "x86-64, jit=off"

plot "clang-load.data" matrix using 1:2:($3 == 0 ? "" : $3) with image, \
     "clang-load.data" matrix using 1:2:($3 == 0 ? "" : sprintf("%g",$3)) with labels
