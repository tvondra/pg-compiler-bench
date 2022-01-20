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

			psql -t -A -F ' ' $DBNAME > gcc-load-$march-$fp.data <<EOF
SELECT "O0", "O1", "O2", "O3", "Ofast", "Og", "Os" FROM crosstab('SELECT
  lpad(version, 10) AS row_name,
  optimization as category,
  duration::int::text as value
 FROM gcc_load_results_agg
WHERE machine = ''$m'' AND march = ''$march'' AND fp = ''$fp''
ORDER BY 1, 2',
'SELECT DISTINCT optimization FROM gcc_load_results_agg ORDER BY 1'
) AS ct(category text, "O0" text, "O1" text, "O2" text, "O3" text, "Ofast" text, "Og" text, "Os" text)
EOF

			psql -t -A -F ' ' $DBNAME > gcc-queries-min-$march-$fp.data <<EOF
SELECT "O0", "O1", "O2", "O3", "Ofast", "Og", "Os" FROM crosstab('SELECT
  lpad(version, 10) AS row_name,
  optimization as category,
  duration_min::int::text as value
 FROM gcc_total_query_results_agg
WHERE machine = ''$m'' AND march = ''$march'' AND fp = ''$fp''
ORDER BY 1, 2',
'SELECT DISTINCT optimization FROM gcc_total_query_results_agg ORDER BY 1'
) AS ct(category text, "O0" text, "O1" text, "O2" text, "O3" text, "Ofast" text, "Og" text, "Os" text)
EOF

			psql -t -A -F ' ' $DBNAME > gcc-queries-max-$march-$fp.data <<EOF
SELECT "O0", "O1", "O2", "O3", "Ofast", "Og", "Os" FROM crosstab('SELECT
  lpad(version, 10) AS row_name,
  optimization as category,
  duration_max::int::text as value
 FROM gcc_total_query_results_agg
WHERE machine = ''$m'' AND march = ''$march'' AND fp = ''$fp''
ORDER BY 1, 2',
'SELECT DISTINCT optimization FROM gcc_total_query_results_agg ORDER BY 1'
) AS ct(category text, "O0" text, "O1" text, "O2" text, "O3" text, "Ofast" text, "Og" text, "Os" text)
EOF

			psql -t -A -F ' ' $DBNAME > gcc-queries-avg-$march-$fp.data <<EOF
SELECT "O0", "O1", "O2", "O3", "Ofast", "Og", "Os" FROM crosstab('SELECT
  lpad(version, 10) AS row_name,
  optimization as category,
  duration_avg::int::text as value
 FROM gcc_total_query_results_agg
WHERE machine = ''$m'' AND march = ''$march'' AND fp = ''$fp''
ORDER BY 1, 2',
'SELECT DISTINCT optimization FROM gcc_total_query_results_agg ORDER BY 1'
) AS ct(category text, "O0" text, "O1" text, "O2" text, "O3" text, "Ofast" text, "Og" text, "Os" text)
EOF

		done

	done

	# now clang
	psql -t -A -F ' ' $DBNAME > clang-load.data <<EOF
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

		psql -t -A -F ' ' $DBNAME > clang-queries-min-$jit.data <<EOF
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

		psql -t -A -F ' ' $DBNAME > clang-queries-max-$jit.data <<EOF
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

		psql -t -A -F ' ' $DBNAME > clang-queries-avg-$jit.data <<EOF
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

	mv *.data $outdir/

done
