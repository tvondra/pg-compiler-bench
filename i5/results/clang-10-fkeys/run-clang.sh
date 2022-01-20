#!/bin/bash

PATH_OLD=$PATH
BUILD_DIR=/var/lib/postgresql/builds
LOG_DIR=/var/lib/postgresql/compiler-test/logs

killall -9 postgres
sleep 10

for cc in 12 11 10 9; do

	for march in "x86-64"; do

		for optim in O0 O1 O2 O3 Os Oz Og Ofast; do

			# for fp in "no-omit-frame-pointer" "omit-frame-pointer"; do

				BUILD="pg-clang-$cc-$march-$optim"
				mkdir $LOG_DIR/$BUILD

				pushd ~/postgres

				PATH=/usr/lib/llvm/$cc/bin:$PATH_OLD

				CC=clang ./configure --prefix=$BUILD_DIR/$BUILD --enable-debug --with-llvm CFLAGS="-march=$march -$optim" > $LOG_DIR/$BUILD/configure.log 2>&1

				make -s clean > /dev/null 2>&1

				make -s -j4 install > $LOG_DIR/$BUILD/make.log 2>&1

				popd

				PATH=$BUILD_DIR/$BUILD/bin:$PATH

				pg_ctl -D /mnt/raid/data-tpch -l $LOG_DIR/$BUILD/pg.log -w start

				ps ax > $LOG_DIR/$BUILD/ps.log 2>&1

				pg_config > $LOG_DIR/$BUILD/pg_config.log 2>&1

				dropdb test
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

				for jit in on off; do

					psql test -c "alter system set jit = $jit" > /dev/null 2>&1

					psql test -c "select pg_reload_conf()" > /dev/null 2>&1

					for q in `ls queries`; do

						for r in `seq 1 3`; do

							s=`psql test -t -A -c "select extract(epoch from now())"`

							psql test < queries/$q >> $LOG_DIR/$BUILD/queries.log 2>&1

							t=`psql test -t -A -c "select extract(epoch from now()) - $s"`

							echo "$cc;$march;$optim;$jit;$q;$r;$t" >> queries.csv 2>&1

						done

						echo "===== $q jit=$jit =====" >> $LOG_DIR/$BUILD/explain.log 2>&1

						psql test < explain/$q >> $LOG_DIR/$BUILD/explain.log 2>&1

					done

				done

				pg_ctl -D /mnt/raid/data-tpch -l $LOG_DIR/$BUILD/pg.log -w stop

			# done

		done

	done

done
