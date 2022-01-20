set terminal postscript eps size 6,2 enhanced color font 'Helvetica,12'
set output 'heatmap-gcc-load.eps'

set palette defined (0 "white", 1 "red")

set key off

# set labels for x/y axis to block sizes"
XTICS="O0 O1 O2 O3 Ofast Og Os"
YTICS="4.8.5 9.3.0 10.3.0 11.2.0"

set for [i=1:words(XTICS)] xtics ( word(XTICS,i) i-1 )
set for [i=1:words(YTICS)] ytics ( word(YTICS,i) i-1 )

# don't show color scale next to the heatmap
unset colorbox

set datafile separator ","
set yrange [*:*] reverse

set multiplot layout 2, 2 rowsfirst

set title "gcc / load / x86-64, -fno-omit-frame-pointer"

plot "gcc-load-x86-64-no-omit-frame-pointer.data" matrix using 1:2:($3 == 0 ? "" : $3) with image, \
     "gcc-load-x86-64-no-omit-frame-pointer.data" matrix using 1:2:($3 == 0 ? "" : sprintf("%g",$3)) with labels

set title "gcc / load / x86-64, -fomit-frame-pointer"

plot "gcc-load-x86-64-omit-frame-pointer.data" matrix using 1:2:($3 == 0 ? "" : $3) with image, \
     "gcc-load-x86-64-omit-frame-pointer.data" matrix using 1:2:($3 == 0 ? "" : sprintf("%g",$3)) with labels


set title "gcc / load / native, -fno-omit-frame-pointer"

plot "gcc-load-native-no-omit-frame-pointer.data" matrix using 1:2:($3 == 0 ? "" : $3) with image, \
     "gcc-load-native-no-omit-frame-pointer.data" matrix using 1:2:($3 == 0 ? "" : sprintf("%g",$3)) with labels

set title "gcc / load / native, -fomit-frame-pointer"

plot "gcc-load-native-omit-frame-pointer.data" matrix using 1:2:($3 == 0 ? "" : $3) with image, \
     "gcc-load-native-omit-frame-pointer.data" matrix using 1:2:($3 == 0 ? "" : sprintf("%g",$3)) with labels
