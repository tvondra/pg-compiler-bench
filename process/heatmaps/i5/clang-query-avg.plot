set terminal postscript eps size 6,1.25 enhanced color font 'Helvetica,12'
set output 'heatmap-clang-queries-avg.eps'

set palette defined (0 "white", 1 "red")

set key off

# set labels for x/y axis to block sizes"
XTICS="O0 O1 O2 O3 Ofast Og Os Oz"
YTICS="9 10 11 12"

set for [i=1:words(XTICS)] xtics ( word(XTICS,i) i-1 )
set for [i=1:words(YTICS)] ytics ( word(YTICS,i) i-1 )

# don't show color scale next to the heatmap
unset colorbox

set datafile separator ","
set yrange [*:*] reverse

set multiplot layout 1, 2 rowsfirst

set title "clang / queries avg / x86-64, jit=off"

plot "clang-queries-avg-off.data" matrix using 1:2:($3 == 0 ? "" : $3) with image, \
     "clang-queries-avg-off.data" matrix using 1:2:($3 == 0 ? "" : sprintf("%g",$3)) with labels

set title "clang / queries avg / x86-64, jit=on"

plot "clang-queries-avg-on.data" matrix using 1:2:($3 == 0 ? "" : $3) with image, \
     "clang-queries-avg-on.data" matrix using 1:2:($3 == 0 ? "" : sprintf("%g",$3)) with labels
