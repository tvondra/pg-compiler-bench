#!/bin/bash

PATH_OLD=$PATH
BUILD_DIR=/var/lib/postgresql/builds
LOG_DIR=/var/lib/postgresql/compiler-test/logs

killall -q -9 postgres
sleep 10

for cc in 10.3.0 11.2.0 9.3.0 4.8.5; do

	for march in "x86-64" "native"; do

		for optim in O0 O1 O2 O3 Os Og Ofast; do

			for fp in "no-omit-frame-pointer" "omit-frame-pointer"; do

				BUILD="pg-gcc-$cc-$march-$optim-$fp"
				mkdir $LOG_DIR/$BUILD

				pushd ~/postgres

				CC=gcc-$cc ./configure --prefix=$BUILD_DIR/$BUILD --enable-debug CFLAGS="-march=$march -$optim -f$fp" > $LOG_DIR/$BUILD/configure.log 2>&1

				make -s clean > /dev/null 2>&1

				make -s -j4 install > $LOG_DIR/$BUILD/make.log 2>&1

				popd

				PATH=$BUILD_DIR/$BUILD/bin:$PATH_OLD

				pg_ctl -D /mnt/raid/data-tpch -l $LOG_DIR/$BUILD/pg.log -w start

				ps ax > $LOG_DIR/$BUILD/ps.log 2>&1

				pg_config > $LOG_DIR/$BUILD/pg_config.log 2>&1

				dropdb --if-exists test
				createdb test

				psql test < sql/schema.sql > $LOG_DIR/$BUILD/schema.log 2>&1

				s=`psql -t -A test -c "select extract(epoch from now())"`
				psql test < sql/load.sql > $LOG_DIR/$BUILD/load.log 2>&1
				d=`psql -t -A test -c "select extract(epoch from now()) - $s"`

				echo "$cc;$march;$optim;$fp;copy;$d" >> load.csv 2>&1

				s=`psql -t -A test -c "select extract(epoch from now())"`
				psql test < sql/indexes.sql > $LOG_DIR/$BUILD/indexes.log 2>&1
				d=`psql -t -A test -c "select extract(epoch from now()) - $s"`

				echo "$cc;$march;$optim;$fp;indexes;$d" >> load.csv 2>&1

				s=`psql -t -A test -c "select extract(epoch from now())"`
				psql test < sql/pkey.sql > $LOG_DIR/$BUILD/pkey.log 2>&1
				d=`psql -t -A test -c "select extract(epoch from now()) - $s"`

				echo "$cc;$march;$optim;$fp;pkeys;$d" >> load.csv 2>&1

				s=`psql -t -A test -c "select extract(epoch from now())"`
				psql test < sql/fkey.sql > $LOG_DIR/$BUILD/fkey.log 2>&1
				d=`psql -t -A test -c "select extract(epoch from now()) - $s"`

				echo "$cc;$march;$optim;$fp;fkeys;$d" >> load.csv 2>&1

				s=`psql -t -A test -c "select extract(epoch from now())"`
				psql test -c "vacuum analyze" > /dev/null 2>&1
				d=`psql -t -A test -c "select extract(epoch from now()) - $s"`

				echo "$cc;$march;$optim;$fp;analyze;$d" >> load.csv 2>&1

				# create directory for explains and query results
				mkdir $LOG_DIR/$BUILD/explains/
				mkdir $LOG_DIR/$BUILD/results/

				# run just the 22 standard queries, ignore the flattened variants etc.
				for q in `seq 1 22`; do

					# restart the server before each query, drop caches
					pg_ctl -D /mnt/raid/data-tpch -l $LOG_DIR/$BUILD/pg.log -w restart
					sudo ./drop-caches.sh

					# do the plain explain
					sed 's/EXPLAIN_COMNAND/explain/g' explain/$q.sql | psql test >> $LOG_DIR/$BUILD/explains/$q.log 2>&1

					# calculate hash of the explain, so that we can compare later
					hp=`md5sum $LOG_DIR/$BUILD/explains/$q.log | awk '{print $1}'`

					# restart the server again - some of the explains may create objects etc.
					pg_ctl -D /mnt/raid/data-tpch -l $LOG_DIR/$BUILD/pg.log -w restart
					sudo ./drop-caches.sh

					# now do three runs for the query
					for r in `seq 1 3`; do

						s=`psql test -t -A -c "select extract(epoch from now())"`

						psql test < queries/$q >> $LOG_DIR/$BUILD/results/$q.$r.log 2>&1

						t=`psql test -t -A -c "select extract(epoch from now()) - $s"`

						# calculate hash of the result, so that we can compare later
						hr=`md5sum $LOG_DIR/$BUILD/results/$q.$r.log | awk '{print $1}'`

						# we assume the plans do not change
						echo "$cc;$march;$optim;$fp;$q;$r;$t;$hp;$hr" >> queries.csv 2>&1

					done

				done

				pg_ctl -D /mnt/raid/data-tpch -l $LOG_DIR/$BUILD/pg.log -w stop

			done

		done

	done

done

