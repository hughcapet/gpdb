/* contrib/pg_stat_statements/pg_stat_statements--1.7--1.8.sql */

-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION pg_stat_statements UPDATE TO '1.8'" to load this file. \quit

ALTER EXTENSION pg_stat_statements DROP VIEW pg_stat_statements;
ALTER EXTENSION pg_stat_statements DROP FUNCTION pg_stat_statements(boolean);
ALTER EXTENSION pg_stat_statements DROP FUNCTION pg_stat_statements_reset(Oid, Oid, bigint);

/* Then we can drop them */
DROP VIEW pg_stat_statements;
DROP FUNCTION pg_stat_statements(boolean);
DROP FUNCTION pg_stat_statements_reset(Oid, Oid, bigint);

/* Now redefine */
CREATE FUNCTION pg_stat_statements_local(IN showtext boolean,
    OUT userid oid,
    OUT dbid oid,
    OUT queryid bigint,
    OUT query text,
    OUT calls int8,
    OUT total_time float8,
    OUT min_time float8,
    OUT max_time float8,
    OUT mean_time float8,
    OUT stddev_time float8,
    OUT rows int8,
    OUT shared_blks_hit int8,
    OUT shared_blks_read int8,
    OUT shared_blks_dirtied int8,
    OUT shared_blks_written int8,
    OUT local_blks_hit int8,
    OUT local_blks_read int8,
    OUT local_blks_dirtied int8,
    OUT local_blks_written int8,
    OUT temp_blks_read int8,
    OUT temp_blks_written int8,
    OUT blk_read_time float8,
    OUT blk_write_time float8
)
RETURNS SETOF record
AS 'MODULE_PATHNAME', 'pg_stat_statements_1_3'
LANGUAGE C STRICT VOLATILE;

CREATE FUNCTION pg_stat_statements_segments(IN showtext boolean,
    OUT gp_segment_id int8,
    OUT userid oid,
    OUT dbid oid,
    OUT queryid bigint,
    OUT query text,
    OUT calls int8,
    OUT total_time float8,
    OUT min_time float8,
    OUT max_time float8,
    OUT mean_time float8,
    OUT stddev_time float8,
    OUT rows int8,
    OUT shared_blks_hit int8,
    OUT shared_blks_read int8,
    OUT shared_blks_dirtied int8,
    OUT shared_blks_written int8,
    OUT local_blks_hit int8,
    OUT local_blks_read int8,
    OUT local_blks_dirtied int8,
    OUT local_blks_written int8,
    OUT temp_blks_read int8,
    OUT temp_blks_written int8,
    OUT blk_read_time float8,
    OUT blk_write_time float8
)
RETURNS SETOF record
LANGUAGE SQL AS
$$
 select gp_execution_segment()::int8 as gp_segment_id, * from pg_stat_statements_local(showtext);
$$
EXECUTE ON ALL SEGMENTS;

CREATE FUNCTION pg_stat_statements(IN showtext boolean,
    OUT gp_segment_id int8,
    OUT userid oid,
    OUT dbid oid,
    OUT queryid bigint,
    OUT query text,
    OUT calls int8,
    OUT total_time float8,
    OUT min_time float8,
    OUT max_time float8,
    OUT mean_time float8,
    OUT stddev_time float8,
    OUT rows int8,
    OUT shared_blks_hit int8,
    OUT shared_blks_read int8,
    OUT shared_blks_dirtied int8,
    OUT shared_blks_written int8,
    OUT local_blks_hit int8,
    OUT local_blks_read int8,
    OUT local_blks_dirtied int8,
    OUT local_blks_written int8,
    OUT temp_blks_read int8,
    OUT temp_blks_written int8,
    OUT blk_read_time float8,
    OUT blk_write_time float8
)
RETURNS SETOF record
LANGUAGE SQL AS
$$
  SELECT -1 as gp_segment_id, * FROM pg_stat_statements_local(showtext)
  UNION ALL
  SELECT
  seg.gp_segment_id,
  seg.userid,
  seg.dbid,
  seg.queryid,
  COALESCE(disp.query, seg.query),
  seg.calls,
  seg.total_time,
  seg.min_time,
  seg.max_time,
  seg.mean_time,
  seg.stddev_time,
  seg.rows,
  seg.shared_blks_hit,
  seg.shared_blks_read,
  seg.shared_blks_dirtied,
  seg.shared_blks_written,
  seg.local_blks_hit,
  seg.local_blks_read,
  seg.local_blks_dirtied,
  seg.local_blks_written,
  seg.temp_blks_read,
  seg.temp_blks_written,
  seg.blk_read_time,
  seg.blk_write_time
  FROM pg_stat_statements_segments(showtext) seg
  LEFT JOIN pg_stat_statements_local(showtext) disp USING (queryid);
$$;


CREATE VIEW pg_stat_statements AS
  SELECT * FROM pg_stat_statements(true);

GRANT SELECT ON pg_stat_statements TO PUBLIC;


CREATE FUNCTION pg_stat_statements_reset_local(IN userid Oid DEFAULT 0,
	IN dbid Oid DEFAULT 0,
	IN queryid bigint DEFAULT 0
)
RETURNS void
AS 'MODULE_PATHNAME', 'pg_stat_statements_reset_1_7'
LANGUAGE C STRICT PARALLEL SAFE;

CREATE FUNCTION pg_stat_statements_reset_segments(IN userid Oid DEFAULT 0,
	IN dbid Oid DEFAULT 0,
	IN queryid bigint DEFAULT 0
)
RETURNS void
AS 'MODULE_PATHNAME', 'pg_stat_statements_reset_1_7'
LANGUAGE C STRICT PARALLEL SAFE
EXECUTE ON ALL SEGMENTS;

CREATE FUNCTION pg_stat_statements_reset(IN userid Oid DEFAULT 0,
	IN dbid Oid DEFAULT 0,
	IN queryid bigint DEFAULT 0
)
RETURNS void
LANGUAGE SQL AS
$$
  SELECT pg_stat_statements_reset_segments(userid, dbid, queryid);
  SELECT pg_stat_statements_reset_local(userid, dbid, queryid);
$$
STRICT PARALLEL SAFE;

-- Don't want this to be available to non-superusers.
REVOKE ALL ON FUNCTION pg_stat_statements_reset(Oid, Oid, bigint) FROM PUBLIC;
