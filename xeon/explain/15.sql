-- using 1583427054 as a seed to the RNG

explain (settings, analyze)
        select
                l_suppkey,
                sum(l_extendedprice * (1 - l_discount))
        from
                lineitem
        where
                l_shipdate >= date '1996-01-01'
                and l_shipdate < date '1996-04-01'
        group by
                l_suppkey;

create view revenue0 (supplier_no, total_revenue) as
	select
		l_suppkey,
		sum(l_extendedprice * (1 - l_discount))
	from
		lineitem
	where
		l_shipdate >= date '1996-01-01'
		and l_shipdate < date '1996-04-01'
	group by
		l_suppkey;

explain (settings, analyze)
select
	s_suppkey,
	s_name,
	s_address,
	s_phone,
	total_revenue
from
	supplier,
	revenue0
where
	s_suppkey = supplier_no
	and total_revenue = (
		select
			max(total_revenue)
		from
			revenue0
	)
order by
	s_suppkey
LIMIT 1;

drop view revenue0;