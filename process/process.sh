#!/bin/bash

DBNAME=block_bench_results

# get parent directory
ROOTDIR=`realpath $0`
ROOTDIR=`dirname $ROOTDIR`
ROOTDIR=`dirname $ROOTDIR`

echo "top directory: $ROOTDIR"

dropdb --if-exists $DBNAME
createdb $DBNAME

psql $DBNAME < stats.sql

for m in i5 xeon; do

	# remove stale generated files (if any)
	rm -f *.csv

	cat $ROOTDIR/$m/results/clang-10-fkeys/queries.csv | sed "s/^/$m;/" | sed 's/;;/;/' | sed 's/.sql//' | grep -v flattened >> clang-queries.csv
	cat $ROOTDIR/$m/results/clang-10-fkeys/load.csv | sed "s/^/$m;/" | sed 's/;;/;/' >> clang-load.csv

	cat $ROOTDIR/$m/results/gcc-10-fkeys/queries.csv | sed "s/^/$m;/" | sed 's/;;/;/' | sed 's/.sql//' | sed 's/gcc-//' | grep -v flattened >> gcc-queries.csv
	cat $ROOTDIR/$m/results/gcc-10-fkeys/load.csv | sed "s/^/$m;/" | sed 's/;;/;/' | sed 's/gcc-//' >> gcc-load.csv


	cat clang-queries.csv | psql $DBNAME -c "copy clang_query_results (machine, version, march, optimization, jit, query, run, duration) from stdin with (format csv, delimiter ';')"
	cat gcc-queries.csv | psql $DBNAME -c "copy gcc_query_results (machine, version, march, optimization, fp, query, run, duration) from stdin with (format csv, delimiter ';')"

	cat clang-load.csv | psql $DBNAME -c "copy clang_load_results (machine, version, march, optimization, step, duration) from stdin with (format csv, delimiter ';')"

	if [ "$m" == "i5" ]; then
		cat gcc-load.csv | psql $DBNAME -c "copy gcc_load_results (machine, version, march, optimization, step, duration) from stdin with (format csv, delimiter ';')"
	else
		cat gcc-load.csv | psql $DBNAME -c "copy gcc_load_results (machine, version, march, optimization, fp, step, duration) from stdin with (format csv, delimiter ';')"
	fi

done

psql $DBNAME <<EOF
WITH src AS (
  SELECT
    machine,
    version,
    march,
    optimization,
    step,
    min(id) as min_id
  FROM
    gcc_load_results
  WHERE
    machine = 'i5'
  GROUP BY 1, 2, 3, 4, 5
)
UPDATE gcc_load_results SET fp = 'no-omit-frame-pointer' WHERE machine = 'i5' AND fp IS NULL AND id IN (SELECT min_id FROM src);

UPDATE gcc_load_results SET fp = 'omit-frame-pointer' WHERE machine = 'i5' AND fp IS NULL;
EOF

psql $DBNAME -c "vacuum analyze"

psql $DBNAME -A -c "select * from clang_query_results_agg" > clang_query_results_agg.csv
psql $DBNAME -A -c "select * from gcc_query_results_agg" > gcc_query_results_agg.csv

psql $DBNAME -A -c "select * from clang_load_results_agg" > clang_load_results_agg.csv
psql $DBNAME -A -c "select * from gcc_load_results_agg" > gcc_load_results_agg.csv
