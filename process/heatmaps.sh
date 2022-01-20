#!/usr/bin/bash

DBNAME=block_bench_results

# get parent directory
ROOTDIR=`realpath $0`
ROOTDIR=`dirname $ROOTDIR`
ROOTDIR=`dirname $ROOTDIR`

echo "top directory: $ROOTDIR"

echo "generating heatmaps"

# remove stale generated files (if any)
rm -Rf heatmaps
mkdir heatmaps

psql $DBNAME -c "create extension if not exists tablefunc"

for m in i5 xeon; do

	outdir="heatmaps/$m"
	mkdir -p $outdir

	cp heatmap.template heatmap.plot

	# gcc first
	for march in 'x86-64' 'native'; do

		for fp in 'omit-frame-pointer' 'no-omit-frame-pointer'; do

			psql -t -A -F ',' $DBNAME > gcc-load-$march-$fp.data <<EOF
SELECT "O0", "O1", "O2", "O3", "Ofast", "Og", "Os" FROM crosstab('SELECT
  lpad(version, 10) AS row_name,
  optimization as category,
  COALESCE(duration::int::text, ''0'') as value
 FROM gcc_load_results_agg
WHERE machine = ''$m'' AND march = ''$march'' AND fp = ''$fp''
ORDER BY 1, 2',
'SELECT DISTINCT optimization FROM gcc_load_results_agg ORDER BY 1'
) AS ct(category text, "O0" text, "O1" text, "O2" text, "O3" text, "Ofast" text, "Og" text, "Os" text)
EOF

			psql -t -A -F ',' $DBNAME > gcc-queries-min-$march-$fp.data <<EOF
SELECT "O0", "O1", "O2", "O3", "Ofast", "Og", "Os" FROM crosstab('SELECT
  lpad(version, 10) AS row_name,
  optimization as category,
  COALESCE(duration_min::int::text, ''0'') as value
 FROM gcc_total_query_results_agg
WHERE machine = ''$m'' AND march = ''$march'' AND fp = ''$fp''
ORDER BY 1, 2',
'SELECT DISTINCT optimization FROM gcc_total_query_results_agg ORDER BY 1'
) AS ct(category text, "O0" text, "O1" text, "O2" text, "O3" text, "Ofast" text, "Og" text, "Os" text)
EOF

			psql -t -A -F ',' $DBNAME > gcc-queries-max-$march-$fp.data <<EOF
SELECT "O0", "O1", "O2", "O3", "Ofast", "Og", "Os" FROM crosstab('SELECT
  lpad(version, 10) AS row_name,
  optimization as category,
  COALESCE(duration_max::int::text, ''0'') as value
 FROM gcc_total_query_results_agg
WHERE machine = ''$m'' AND march = ''$march'' AND fp = ''$fp''
ORDER BY 1, 2',
'SELECT DISTINCT optimization FROM gcc_total_query_results_agg ORDER BY 1'
) AS ct(category text, "O0" text, "O1" text, "O2" text, "O3" text, "Ofast" text, "Og" text, "Os" text)
EOF

			psql -t -A -F ',' $DBNAME > gcc-queries-avg-$march-$fp.data <<EOF
SELECT "O0", "O1", "O2", "O3", "Ofast", "Og", "Os" FROM crosstab('SELECT
  lpad(version, 10) AS row_name,
  optimization as category,
  COALESCE(duration_avg::int::text, ''0'') as value
 FROM gcc_total_query_results_agg
WHERE machine = ''$m'' AND march = ''$march'' AND fp = ''$fp''
ORDER BY 1, 2',
'SELECT DISTINCT optimization FROM gcc_total_query_results_agg ORDER BY 1'
) AS ct(category text, "O0" text, "O1" text, "O2" text, "O3" text, "Ofast" text, "Og" text, "Os" text)
EOF

		done

	done

	xtics=`psql $DBNAME -t -A -c "SELECT string_agg(optimization, ' ') FROM (SELECT DISTINCT optimization FROM gcc_total_query_results_agg WHERE machine = '$m' ORDER BY 1) foo"`
	ytics=`psql $DBNAME -t -A -c "SELECT string_agg(trim(version), ' ') FROM (SELECT DISTINCT lpad(version,10) AS version FROM gcc_total_query_results_agg WHERE machine = '$m' ORDER BY 1) foo"`

	sed 's/DATASET/gcc-load/g' heatmap-gcc.template | sed "s/XTICS_DATA/$xtics/" | sed "s/YTICS_DATA/$ytics/" | sed "s/TITLE/load/" > gcc-load.plot
	sed 's/DATASET/gcc-queries-min/g' heatmap-gcc.template | sed "s/XTICS_DATA/$xtics/" | sed "s/YTICS_DATA/$ytics/" | sed "s/TITLE/queries min/" > gcc-query-min.plot
	sed 's/DATASET/gcc-queries-max/g' heatmap-gcc.template | sed "s/XTICS_DATA/$xtics/" | sed "s/YTICS_DATA/$ytics/" | sed "s/TITLE/queries max/" > gcc-query-max.plot
	sed 's/DATASET/gcc-queries-avg/g' heatmap-gcc.template | sed "s/XTICS_DATA/$xtics/" | sed "s/YTICS_DATA/$ytics/" | sed "s/TITLE/queries avg/" > gcc-query-avg.plot

	gnuplot gcc-load.plot
	gnuplot gcc-query-min.plot
	gnuplot gcc-query-max.plot
	gnuplot gcc-query-avg.plot

	# now clang
	psql -t -A -F ',' $DBNAME > clang-load.data <<EOF
SELECT "O0", "O1", "O2", "O3", "Og", "Os", "Oz" FROM crosstab('SELECT
  lpad(version, 10) AS row_name,
  optimization as category,
  duration::int::text as value
 FROM clang_load_results_agg
WHERE machine = ''$m'' AND duration IS NOT NULL
ORDER BY 1, 2',
'SELECT DISTINCT optimization FROM clang_load_results_agg WHERE duration IS NOT NULL ORDER BY 1'
) AS ct(category text, "O0" text, "O1" text, "O2" text, "O3" text, "Og" text, "Os" text, "Oz" text)
EOF

	for jit in on off; do

		psql -t -A -F ',' $DBNAME > clang-queries-min-$jit.data <<EOF
	SELECT "O0", "O1", "O2", "O3", "Og", "Os", "Oz" FROM crosstab('SELECT
	  lpad(version, 10) AS row_name,
	  optimization as category,
	  duration_min::int::text as value
	 FROM clang_total_query_results_agg
	WHERE machine = ''$m'' AND jit = ''$jit''
	ORDER BY 1, 2',
	'SELECT DISTINCT optimization FROM clang_total_query_results_agg WHERE duration_min IS NOT NULL ORDER BY 1'
	) AS ct(category text, "O0" text, "O1" text, "O2" text, "O3" text, "Og" text, "Os" text, "Oz" text)
EOF

		psql -t -A -F ',' $DBNAME > clang-queries-max-$jit.data <<EOF
	SELECT "O0", "O1", "O2", "O3", "Og", "Os", "Oz" FROM crosstab('SELECT
	  lpad(version, 10) AS row_name,
	  optimization as category,
	  duration_max::int::text as value
	 FROM clang_total_query_results_agg
	WHERE machine = ''$m'' AND jit = ''$jit''
	ORDER BY 1, 2',
	'SELECT DISTINCT optimization FROM clang_total_query_results_agg WHERE duration_min IS NOT NULL ORDER BY 1'
	) AS ct(category text, "O0" text, "O1" text, "O2" text, "O3" text, "Og" text, "Os" text, "Oz" text)
EOF

		psql -t -A -F ',' $DBNAME > clang-queries-avg-$jit.data <<EOF
	SELECT "O0", "O1", "O2", "O3", "Og", "Os", "Oz" FROM crosstab('SELECT
	  lpad(version, 10) AS row_name,
	  optimization as category,
	  duration_avg::int::text as value
	 FROM clang_total_query_results_agg
	WHERE machine = ''$m'' AND jit = ''$jit''
	ORDER BY 1, 2',
	'SELECT DISTINCT optimization FROM clang_total_query_results_agg WHERE duration_min IS NOT NULL ORDER BY 1'
	) AS ct(category text, "O0" text, "O1" text, "O2" text, "O3" text, "Og" text, "Os" text, "Oz" text)
EOF

	done

	xtics=`psql $DBNAME -t -A -c "SELECT string_agg(optimization, ' ') FROM (SELECT DISTINCT optimization FROM clang_total_query_results_agg WHERE machine = '$m' ORDER BY 1) foo"`
	ytics=`psql $DBNAME -t -A -c "SELECT string_agg(trim(version), ' ') FROM (SELECT DISTINCT lpad(version,10) AS version FROM clang_total_query_results_agg WHERE machine = '$m' ORDER BY 1) foo"`

	sed 's/DATASET/clang-load/g' heatmap-clang-load.template | sed "s/XTICS_DATA/$xtics/" | sed "s/YTICS_DATA/$ytics/" | sed "s/TITLE/load/" > clang-load.plot
	sed 's/DATASET/clang-queries-min/g' heatmap-clang-queries.template | sed "s/XTICS_DATA/$xtics/" | sed "s/YTICS_DATA/$ytics/" | sed "s/TITLE/queries min/" > clang-query-min.plot
	sed 's/DATASET/clang-queries-max/g' heatmap-clang-queries.template | sed "s/XTICS_DATA/$xtics/" | sed "s/YTICS_DATA/$ytics/" | sed "s/TITLE/queries max/" > clang-query-max.plot
	sed 's/DATASET/clang-queries-avg/g' heatmap-clang-queries.template | sed "s/XTICS_DATA/$xtics/" | sed "s/YTICS_DATA/$ytics/" | sed "s/TITLE/queries avg/" > clang-query-avg.plot

	gnuplot clang-load.plot
	gnuplot clang-query-min.plot
	gnuplot clang-query-max.plot
	gnuplot clang-query-avg.plot

	mv *.data *.plot *.eps $outdir/

done
