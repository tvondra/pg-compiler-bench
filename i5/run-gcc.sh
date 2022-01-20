#!/bin/bash

PATH_OLD=$PATH
BUILD_DIR=/var/lib/postgresql/builds
LOG_DIR=/var/lib/postgresql/compiler-test/logs


for cc in gcc-10.3.0 gcc-11.2.0 gcc-9.3.0 gcc-4.8.5; do

	for march in "x86-64" "native"; do

		for optim in O0 O1 O2 O3 Os Og Ofast; do

			for fp in "no-omit-frame-pointer" "omit-frame-pointer"; do

				BUILD="pg-$cc-$march-$optim-$fp"
				mkdir $LOG_DIR/$BUILD

				pushd ~/postgres

				CC=$cc ./configure --prefix=$BUILD_DIR/$BUILD --enable-debug CFLAGS="-march=$march -$optim -f$fp" > $LOG_DIR/$BUILD/configure.log 2>&1

				make -s clean > /dev/null 2>&1

				make -s -j4 install > $LOG_DIR/$BUILD/make.log 2>&1

				popd

				PATH=$BUILD_DIR/$BUILD/bin:$PATH_OLD

				pg_ctl -D /mnt/raid/data-tpch -l $LOG_DIR/$BUILD/pg.log -w start

				ps ax > $LOG_DIR/$BUILD/ps.log 2>&1

				pg_config > $LOG_DIR/$BUILD/pg_config.log 2>&1

				dropdb test
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
				psql test < sql/alter.sql > $LOG_DIR/$BUILD/alter.log 2>&1
				d=`psql -t -A test -c "select extract(epoch from now()) - $s"`

				echo "$cc;$march;$optim;$fp;alter;$d" >> load.csv 2>&1

				s=`psql -t -A test -c "select extract(epoch from now())"`
				psql test -c "vacuum analyze" > /dev/null 2>&1
				d=`psql -t -A test -c "select extract(epoch from now()) - $s"`

				echo "$cc;$march;$optim;$fp;analyze;$d" >> load.csv 2>&1

				for q in `ls queries`; do

					for r in `seq 1 3`; do

						s=`psql test -t -A -c "select extract(epoch from now())"`

						psql test < queries/$q >> $LOG_DIR/$BUILD/queries.log 2>&1

						t=`psql test -t -A -c "select extract(epoch from now()) - $s"`

						echo "$cc;$march;$optim;$fp;$q;$r;$t" >> queries.csv 2>&1

					done

				done

				pg_ctl -D /mnt/raid/data-tpch -l $LOG_DIR/$BUILD/pg.log -w stop

			done

		done

	done

done
