#!/bin/bash

PATH_OLD=$PATH
BUILD_DIR=/var/lib/postgresql/builds
LOG_DIR=/var/lib/postgresql/compiler-test/logs

killall -q -9 postgres
sleep 10

for cc in 12 11 10 9; do

	for march in "x86-64"; do

		for optim in O0 O1 O2 O3 Os Oz Og Ofast; do

				BUILD="pg-clang-$cc-$march-$optim"
				mkdir $LOG_DIR/$BUILD

				pushd ~/postgres

				PATH=/usr/lib/llvm/$cc/bin:$PATH_OLD

				CC=clang ./configure --prefix=$BUILD_DIR/$BUILD --enable-debug --with-llvm CFLAGS="-march=$march -$optim" > $LOG_DIR/$BUILD/configure.log 2>&1

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

				echo "$cc;$march;$optim;copy;$d" >> load.csv 2>&1

				s=`psql -t -A test -c "select extract(epoch from now())"`
				psql test < sql/indexes.sql > $LOG_DIR/$BUILD/indexes.log 2>&1
				d=`psql -t -A test -c "select extract(epoch from now()) - $s"`

				echo "$cc;$march;$optim;indexes;$d" >> load.csv 2>&1

				s=`psql -t -A test -c "select extract(epoch from now())"`
				psql test < sql/pkey.sql > $LOG_DIR/$BUILD/pkey.log 2>&1
				d=`psql -t -A test -c "select extract(epoch from now()) - $s"`

				echo "$cc;$march;$optim;pkeys;$d" >> load.csv 2>&1

				s=`psql -t -A test -c "select extract(epoch from now())"`
				psql test < sql/fkey.sql > $LOG_DIR/$BUILD/fkey.log 2>&1
				d=`psql -t -A test -c "select extract(epoch from now()) - $s"`

				echo "$cc;$march;$optim;fkeys;$d" >> load.csv 2>&1

				s=`psql -t -A test -c "select extract(epoch from now())"`
				psql test -c "vacuum analyze" > /dev/null 2>&1
				d=`psql -t -A test -c "select extract(epoch from now()) - $s"`

				echo "$cc;$march;$optim;analyze;$d" >> load.csv 2>&1

				# run queries with and without JIT enabled
				for jit in on off; do

					# create directory for explains and query results
					mkdir $LOG_DIR/$BUILD/$jit
					mkdir $LOG_DIR/$BUILD/$jit/explains/
					mkdir $LOG_DIR/$BUILD/$jit/results/

					# enable/disable the JIT
					psql test -c "alter system set jit = $jit" > /dev/null 2>&1
					psql test -c "select pg_reload_conf()" > /dev/null 2>&1

					# run just the 22 standard queries, ignore the flattened variants etc.
					for q in `seq 1 22`; do

						# restart the server before each query, drop caches
						pg_ctl -D /mnt/raid/data-tpch -l $LOG_DIR/$BUILD/pg.log -w restart
						sudo ./drop-caches.sh

						# do the plain explain
						sed 's/EXPLAIN_COMNAND/explain/g' explain/$q.sql | psql test >> $LOG_DIR/$BUILD/$it/explains/$q.log 2>&1

						# calculate hash of the explain, so that we can compare later
						hp=`md5sum $LOG_DIR/$BUILD/$jit/explains/$q.log | awk '{print $1}'`

						# restart the server again - some of the explains may create objects etc.
						pg_ctl -D /mnt/raid/data-tpch -l $LOG_DIR/$BUILD/pg.log -w restart
						sudo ./drop-caches.sh

						# now do three runs for the query
						for r in `seq 1 3`; do

							s=`psql test -t -A -c "select extract(epoch from now())"`

							psql test < queries/$q >> $LOG_DIR/$BUILD/$jit/results/$q.$r.log 2>&1

							t=`psql test -t -A -c "select extract(epoch from now()) - $s"`

							# calculate hash of the result, so that we can compare later
							hr=`md5sum $LOG_DIR/$BUILD/$jit/results/$q.$r.log | awk '{print $1}'`

							# we assume the plans do not change
							echo "$cc;$march;$optim;$jit;$q;$r;$t;$hp;$hr" >> queries.csv 2>&1

						done

					done

				done

				pg_ctl -D /mnt/raid/data-tpch -l $LOG_DIR/$BUILD/pg.log -w stop

		done

	done

done
