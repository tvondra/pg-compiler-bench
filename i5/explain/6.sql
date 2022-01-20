-- using 1583427054 as a seed to the RNG

explain (settings, analyze) select
	sum(l_extendedprice * l_discount) as revenue
from
	lineitem
where
	l_shipdate >= date '1993-01-01'
	and l_shipdate < date '1994-01-01'
	and l_discount between 0.07 - 0.01 and 0.07 + 0.01
	and l_quantity < 25
LIMIT 1;
