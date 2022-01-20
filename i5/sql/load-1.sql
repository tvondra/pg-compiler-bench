COPY part FROM PROGRAM 'gunzip -c /mnt/data/tpch/1/part.csv.gz' WITH (FORMAT csv, DELIMITER '|');

COPY region FROM PROGRAM 'gunzip -c /mnt/data/tpch/1/region.csv.gz' WITH (FORMAT csv, DELIMITER '|');

COPY nation FROM PROGRAM 'gunzip -c /mnt/data/tpch/1/nation.csv.gz' WITH (FORMAT csv, DELIMITER '|');

COPY supplier FROM PROGRAM 'gunzip -c /mnt/data/tpch/1/supplier.csv.gz' WITH (FORMAT csv, DELIMITER '|');

COPY customer FROM PROGRAM 'gunzip -c /mnt/data/tpch/1/customer.csv.gz' WITH (FORMAT csv, DELIMITER '|');

COPY partsupp FROM PROGRAM 'gunzip -c /mnt/data/tpch/1/partsupp.csv.gz' WITH (FORMAT csv, DELIMITER '|');

COPY orders FROM PROGRAM 'gunzip -c /mnt/data/tpch/1/orders.csv.gz' WITH (FORMAT csv, DELIMITER '|');

COPY lineitem FROM PROGRAM 'gunzip -c /mnt/data/tpch/1/lineitem.csv.gz' WITH (FORMAT csv, DELIMITER '|');
