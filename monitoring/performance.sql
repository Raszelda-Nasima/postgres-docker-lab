-- Local PostgreSQL performance/health snapshots. Read-only queries; no extensions required.

\echo 'Database size'
SELECT current_database() AS database_name,
       pg_size_pretty(pg_database_size(current_database())) AS database_size;

\echo 'Table sizes and estimated live/dead rows'
SELECT schemaname, relname AS table_name,
       pg_size_pretty(pg_total_relation_size(relid)) AS total_size,
       n_live_tup AS estimated_live_rows,
       n_dead_tup AS estimated_dead_rows,
       last_analyze, last_autoanalyze
FROM pg_stat_user_tables
ORDER BY pg_total_relation_size(relid) DESC;

\echo 'Cache hit ratio (database-wide; interpret with workload context)'
SELECT blks_hit, blks_read,
       ROUND(100.0 * blks_hit / NULLIF(blks_hit + blks_read, 0), 2) AS cache_hit_percent
FROM pg_stat_database
WHERE datname = current_database();

\echo 'Index usage (statistics reset on server restart or manually)'
SELECT schemaname, relname AS table_name, indexrelname AS index_name,
       idx_scan, idx_tup_read, idx_tup_fetch,
       pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes
ORDER BY idx_scan ASC, pg_relation_size(indexrelid) DESC;
