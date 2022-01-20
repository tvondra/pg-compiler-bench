create table clang_query_results (
  id           serial primary key,
  machine      text,  -- name of the machine
  version      text,  -- clang version
  march        text,  -- architecture
  optimization text,  -- optimization level
  jit          text,  -- JIT enabled/disabled
  query        int,   -- query number (1 .. 22)
  run          int,   -- run (1 .. 3)
  duration     double precision
);

create table clang_load_results (
  id           serial primary key,
  machine      text,  -- name of the machine
  version      text,  -- clang version
  march        text,  -- architecture
  optimization text,  -- optimization level
  step         text,  -- load step (copy, indexes, ...)
  duration     double precision
);

create table gcc_query_results (
  id           serial primary key,
  machine      text,  -- name of the machine
  version      text,  -- gcc version
  march        text,  -- architecture
  optimization text,  -- optimization level
  fp           text,  -- frame pointer
  query        int,   -- query number (1 .. 22)
  run          int,   -- run (1 .. 3)
  duration     double precision
);

create table gcc_load_results (
  id           serial primary key,
  machine      text,  -- name of the machine
  version      text,  -- gcc version
  march        text,  -- architecture
  optimization text,  -- optimization level
  fp           text,  -- frame pointer
  step         text,  -- load step
  duration     double precision
);

create view clang_query_results_agg as
select
    machine,
    version,
    march,
    optimization,
    jit,
    query,
    min(duration) as duration_min,
    max(duration) as duration_max,
    avg(duration) as duration_avg
from clang_query_results
group by 1, 2, 3, 4, 5, 6;

create view clang_total_query_results_agg as
select
    machine,
    version,
    march,
    optimization,
    jit,
    sum(duration_min) as duration_min,
    sum(duration_max) as duration_max,
    sum(duration_avg) as duration_avg
from clang_query_results_agg
group by 1, 2, 3, 4, 5;

create view clang_load_results_agg as
select
    machine,
    version,
    march,
    optimization,
    sum(duration) as duration
from clang_query_results
group by 1, 2, 3, 4;

create view gcc_query_results_agg as
select
    machine,
    version,
    march,
    optimization,
    fp,
    query,
    min(duration) as duration_min,
    max(duration) as duration_max,
    avg(duration) as duration_avg
from gcc_query_results
group by 1, 2, 3, 4, 5, 6;

create view gcc_total_query_results_agg as
select
    machine,
    version,
    march,
    optimization,
    fp,
    sum(duration_min) as duration_min,
    sum(duration_max) as duration_max,
    sum(duration_avg) as duration_avg
from gcc_query_results_agg
group by 1, 2, 3, 4, 5;

create view gcc_load_results_agg as
select
    machine,
    version,
    march,
    optimization,
    fp,
    sum(duration) as duration
from gcc_query_results
group by 1, 2, 3, 4, 5;
