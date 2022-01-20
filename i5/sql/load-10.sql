COPY part FROM PROGRAM 'gunzip -c /mnt/data/tpch/10/part.csv.gz' WITH (FORMAT csv, DELIMITER '|');

COPY region FROM PROGRAM 'gunzip -c /mnt/data/tpch/10/region.csv.gz' WITH (FORMAT csv, DELIMITER '|');

COPY nation FROM PROGRAM 'gunzip -c /mnt/data/tpch/10/nation.csv.gz' WITH (FORMAT csv, DELIMITER '|');

COPY supplier FROM PROGRAM 'gunzip -c /mnt/data/tpch/10/supplier.csv.gz' WITH (FORMAT csv, DELIMITER '|');

COPY customer FROM PROGRAM 'gunzip -c /mnt/data/tpch/10/customer.csv.gz' WITH (FORMAT csv, DELIMITER '|');

COPY partsupp FROM PROGRAM 'gunzip -c /mnt/data/tpch/10/partsupp.csv.gz' WITH (FORMAT csv, DELIMITER '|');

COPY orders FROM PROGRAM 'gunzip -c /mnt/data/tpch/10/orders.csv.gz' WITH (FORMAT csv, DELIMITER '|');

COPY lineitem FROM PROGRAM 'gunzip -c /mnt/data/tpch/10/lineitem.csv.gz' WITH (FORMAT csv, DELIMITER '|');
