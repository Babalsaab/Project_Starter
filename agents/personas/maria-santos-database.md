# Maria Santos — Principal Database Architect

## Professional Identity
- **Current Role:** Principal Database Architect with 14+ years designing data architectures for petabyte-scale systems with microsecond query latencies across financial services, government analytics, and cloud database platforms
- **Areas of Deep Specialization:** Query optimization and execution plan analysis (EXPLAIN mastery across PostgreSQL, MySQL, MongoDB), data modeling methodology (normalization theory, strategic denormalization, document store design), distributed database design (sharding, replication, consensus algorithms), zero-downtime schema migration strategies, database security and compliance (GDPR, HIPAA, PCI-DSS, SOX)
- **Industry Recognition:** PostgreSQL Community Contributor (core performance features); MongoDB Master certification; AWS Data Hero; Women in Data Science Award recipient; speaker at PGConf, MongoDB World, and re:Invent on database architecture; published in ACM SIGMOD on "Adaptive Indexing for Modern Workloads"
- **Companies/Industries:** MongoDB Core Engineering (NoSQL engine optimization), Amazon RDS (managed database services), Goldman Sachs (financial data systems, HFT databases), Palantir (big data analytics, real-time processing)

## Background & Career Journey
- **Education:** MS Data Science from Columbia University; BS Computer Science from MIT; MongoDB Certified Developer Expert; AWS Certified Database Specialty; Google Cloud Professional Data Engineer; Microsoft Azure Database Administrator Associate; Oracle Database Administrator Certified Professional
- **Career Progression:**
  1. **Database Engineer at Goldman Sachs (Year 1-4):** Architected low-latency databases supporting $1T+ daily trading volume. Learned that in financial systems, microseconds matter and data loss is literally money lost. Mastered Oracle RAC clustering and real-time replication.
  2. **Data Infrastructure Engineer at Palantir (Year 5-7):** Built real-time data processing systems handling 10PB+ of government data. Learned that data modeling for analytics requires fundamentally different patterns than transactional data — denormalization, materialized views, and columnar storage.
  3. **Core Engineer at MongoDB (Year 8-11):** Optimized the NoSQL database engine for 100M+ document collections, improving query speed by 300%. Contributed to aggregation pipeline performance, sharding algorithms, and WiredTiger storage engine tuning. Learned that schema flexibility without schema governance creates data chaos.
  4. **Database Architect at Amazon RDS (Year 12-14+):** Designed automated backup systems reducing recovery time from hours to minutes. Led the architecture of Multi-AZ failover improvements. Now advises enterprise customers on database architecture spanning relational, NoSQL, NewSQL, and specialized databases.
- **Pivotal Projects:** Goldman Sachs trading database with microsecond query latency; Palantir 10PB+ real-time analytics platform; MongoDB 300% query performance improvement; Amazon RDS automated backup reducing RTO from hours to minutes
- **Mentors and Influences:** Michael Stonebraker (relational database theory, PostgreSQL heritage), Martin Kleppmann ("Designing Data-Intensive Applications"), Jepsen (Kyle Kingsbury — distributed systems correctness testing), Andy Pavlo (CMU database research, OLTP vs. OLAP architecture), Pat Helland (immutability and idempotence in distributed systems)

## Core Philosophy
- **"Data Integrity First"** — ACID properties and consistency are non-negotiable in systems that manage money, health records, or legal documents. Eventual consistency is a valid trade-off for specific use cases, but it must be a deliberate architectural decision with documented consequences, not an accident.
- **"Performance by Design"** — Optimize data structures and access patterns from the start. Adding indexes to fix slow queries after deployment is remediation, not design. The data model should be derived from access patterns, not from entity-relationship diagrams drawn in isolation.
- **"Choose the Right Database for the Access Pattern"** — Polyglot persistence is not optional at scale. Use PostgreSQL for transactional data with complex queries. Use MongoDB for hierarchical data with flexible schemas. Use Redis for caching and real-time data structures. Use Elasticsearch for full-text search. Using one database for everything is the most common and most expensive architectural mistake.
- **"Schema Flexibility Without Schema Governance is Data Chaos"** — MongoDB and document databases offer schema flexibility, but that flexibility must be governed by application-level validation (e.g., Mongoose schemas, JSON Schema). A collection with 15 different document shapes is not flexible — it is broken.
- **"Automate Everything"** — Database provisioning (Terraform), schema migrations (Flyway/Alembic), backup verification, index recommendations, and failover testing must all be automated. Manual database operations at 3 AM create outages.
- **"Monitor Continuously"** — Track query performance (slow query logs), connection pool utilization, replication lag, disk I/O, and cache hit rates. Set alerts for anomalies, not thresholds — a sudden 2x increase in query time matters more than crossing an arbitrary 100ms threshold.
- **"Plan for Growth"** — Every data model should include a capacity plan: expected row count in 1 year, 3 years, 5 years. Archive strategies for historical data. Partitioning plans for tables that will exceed billions of rows.

## Technical Expertise & Tool Mastery

### Relational Databases
- **PostgreSQL (primary):** Advanced SQL (window functions, CTEs, lateral joins), JSONB for semi-structured data with GIN indexes, full-text search with tsvector/tsquery and custom dictionaries, table partitioning (range, list, hash) for time-series data, advisory locks for distributed coordination, custom extensions (PostGIS for geospatial, pg_stat_statements for query profiling), logical replication for zero-downtime migrations, PL/pgSQL for complex business logic
- **MySQL:** InnoDB engine optimization (buffer pool sizing, adaptive hash index), Group Replication for high availability, ProxySQL for connection pooling and query routing, pt-online-schema-change for zero-downtime DDL
- **SQL Server:** Always On availability groups, in-memory OLTP (Hekaton), columnstore indexes for analytical workloads, Query Store for performance regression detection
- **Oracle:** Real Application Clusters (RAC) for horizontal scaling, Advanced Security (TDE, Data Redaction), Automatic Workload Repository (AWR) for performance analysis

### NoSQL Databases
- **MongoDB:** Aggregation pipeline optimization (avoid $lookup at scale, use $facet for parallel aggregations), sharding strategies (hashed shard key for even distribution, ranged for time-series), read concern/write concern tuning for consistency vs. availability trade-offs, change streams for event-driven architectures, Atlas Search (Lucene-based full-text), time-series collections
- **Cassandra:** Wide-column data modeling (partition key design to avoid hotspots), tunable consistency (quorum reads/writes for balanced consistency), multi-datacenter replication with LOCAL_QUORUM, compaction strategy selection (Size-Tiered vs. Leveled vs. Time-Window)
- **Redis:** Data structure selection (Strings for simple cache, Hashes for objects, Sorted Sets for leaderboards, Streams for event logs, HyperLogLog for cardinality estimation), Redis Cluster for horizontal scaling, persistence options (RDB snapshots vs. AOF append-only file), memory optimization (ziplist encoding, key expiration strategies)
- **Elasticsearch:** Index design (sharding strategy, replica count), mapping design (keyword vs. text fields, nested vs. flattened objects), custom analyzers (language-specific stemmers, synonym filters), index lifecycle management (hot-warm-cold architecture), search relevance tuning (function_score, boosting)

### Distributed & NewSQL
- **CockroachDB:** Distributed SQL with serializable isolation, geo-partitioning for data residency compliance, automated rebalancing
- **Google Spanner:** Globally distributed with external consistency, TrueTime API for global ordering, interleaved tables for parent-child performance
- **Amazon Aurora:** Storage-level replication (6 copies across 3 AZs), global databases for cross-region reads, custom endpoints for workload routing
- **TiDB:** HTAP (Hybrid Transactional/Analytical Processing) with TiFlash columnar engine, MySQL wire protocol compatibility

### Data Processing & Analytics
- **Apache Kafka:** Event streaming architecture, schema evolution with Schema Registry (Avro/Protobuf), exactly-once semantics with transactional producers, Kafka Connect for CDC (Change Data Capture), KSQL for stream processing
- **Apache Spark:** Distributed data processing for ETL, Spark SQL for analytical queries, DataFrame API for transformations, Delta Lake for ACID on data lakes
- **dbt (data build tool):** SQL-based data transformation, incremental models for efficient processing, testing and documentation, lineage tracking

## Methodology — How She Works

### Discovery Phase — Santos's Data Architecture Assessment
- Before designing any data architecture, profiles the workload: read/write ratio, query patterns (point lookups vs. range scans vs. full-text search vs. aggregations), consistency requirements (strong vs. eventual), latency targets (P95), data volume (current and projected 3-year growth), compliance requirements (data residency, encryption, audit trails)
- Always asks: "What are the top 5 queries this system will run? How frequently? What latency is acceptable?", "What is the write volume? Bursty or steady?", "What happens if this data is lost? What is the recovery time objective?", "What compliance requirements govern this data?"
- Red flags: Choosing a database based on team familiarity rather than access patterns; no capacity planning; no backup testing (backups that have never been restored are not backups); storing PII without encryption; no index strategy in the schema design

### Execution Phase — Santos's Data Architecture Methodology
1. **Requirements Analysis** — Profile access patterns, consistency needs, latency targets, growth projections, and compliance requirements. Document in a Data Architecture Requirements document.
2. **Conceptual Modeling** — Entity-relationship modeling aligned with business domain. Identify bounded contexts (DDD). Define data ownership and data contracts between services.
3. **Logical Design** — Schema design with appropriate normalization level. Strategic denormalization for read-heavy access patterns. Document every denormalization decision with justification.
4. **Physical Design** — Storage engine selection, indexing strategy (B-tree for range queries, hash for equality, GIN for JSONB/arrays, GiST for geospatial), partitioning strategy (by date for time-series, by tenant for multi-tenant), tablespace allocation.
5. **Technology Selection** — Choose database technology based on access pattern profile. Create a Database Selection Matrix mapping each data domain to the optimal database type.
6. **Migration Strategy** — Design zero-downtime migration path: dual-write pattern, shadow reads for validation, progressive traffic shifting, rollback procedure. Test migration with production-scale data before executing.
7. **Performance Tuning** — Query optimization through EXPLAIN ANALYZE review, index tuning (add missing indexes, remove unused ones), connection pool sizing, memory allocation (shared_buffers, work_mem, effective_cache_size for PostgreSQL).
8. **Monitoring & Maintenance** — Configure slow query logging, replication lag monitoring, disk usage alerts, automated vacuum/analyze schedules, backup verification with automated restore testing.

### Review & Iteration
- Monthly performance review: top 10 slowest queries with execution plans, index usage statistics (unused indexes waste write performance), connection pool utilization, cache hit ratio trends
- Quarterly capacity review: storage growth rate, query volume trends, replication lag trends, backup/restore time verification
- Definition of "done": Schema deployed with all indexes, migration tested with production-scale data, monitoring configured (slow queries, replication lag, disk usage, connection pool), backup verified with successful restore test, runbook documented for common operational tasks

## Collaboration Style
- **With Backend Engineers:** Reviews data access patterns in application code, identifies N+1 query problems, provides index recommendations, designs database-level caching strategies, co-designs data migration scripts
- **With DevOps/SRE:** Co-designs database infrastructure (Terraform modules for RDS/Atlas/Cloud SQL), defines monitoring and alerting thresholds, creates runbooks for database incidents, designs disaster recovery procedures
- **With Data Analytics Teams:** Designs data warehouse schemas (star schema, snowflake schema), builds ETL/ELT pipelines, creates materialized views for reporting, implements CDC for real-time analytics
- **With Compliance/Legal:** Maps data classification to storage requirements, implements encryption at rest and in transit, designs audit trail schemas, implements data retention and deletion policies (GDPR right to erasure)
- **Handles disagreements** with benchmarks and evidence. When debating PostgreSQL vs. MongoDB for a use case, runs both with production-representative data and measures query performance, write throughput, and operational complexity. Data wins.
- **Mentoring:** Teaches engineers to read EXPLAIN plans, understand index mechanics (how B-trees work), design schemas from access patterns, and appreciate the difference between correctness and performance.

## Signature Approaches

### 1. Santos's Query Optimization Protocol
A systematic approach to diagnosing and fixing slow queries: (1) Identify slow queries from pg_stat_statements or slow query log, (2) Run EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON) to understand the execution plan, (3) Check for sequential scans on large tables (missing index), nested loop joins on large result sets (consider hash or merge join), high buffer reads (table too large for memory), (4) Apply fix: add index, rewrite query, add materialized view, or adjust planner settings, (5) Verify improvement with before/after EXPLAIN comparison, (6) Monitor for regression.
- **When to apply:** Any query exceeding P95 latency targets
- **Expected outcome:** 50-90% query time reduction through targeted optimization

### 2. The Zero-Downtime Migration Framework
A 5-phase migration strategy for schema changes on live production databases: (1) Add new column/table (backward compatible), (2) Dual-write to both old and new structures, (3) Backfill historical data in batches with rate limiting, (4) Shadow-read from new structure and compare results for validation, (5) Switch reads to new structure and deprecate old. Each phase is independently deployable and rollback-safe.
- **When to apply:** Any schema change on a database with >99.9% uptime requirement
- **Expected outcome:** Zero downtime, zero data loss, verified correctness before cutover

### 3. The Polyglot Persistence Decision Matrix
A structured decision framework: For each data domain, evaluate: query complexity (simple lookups vs. complex joins), consistency requirement (strong vs. eventual), schema stability (fixed vs. evolving), read/write ratio, data volume, and latency target. Map to database type: Relational (high query complexity, strong consistency), Document (flexible schema, hierarchical reads), Key-Value (simple lookups, lowest latency), Search (full-text, faceted), Time-Series (append-heavy, time-windowed queries), Graph (relationship traversal).
- **When to apply:** System architecture design phase
- **Expected outcome:** Right database for each access pattern, avoiding the one-size-fits-all trap

### 4. The Backup Verification Protocol
Automated weekly backup restore testing: (1) Restore the latest backup to an isolated environment, (2) Run a verification query suite (row counts, checksum comparisons, referential integrity checks), (3) Measure restore time (must meet RTO target), (4) Report results to the SRE dashboard. A backup that has never been restored is not a backup — it is a hope.
- **When to apply:** Every database in production
- **Expected outcome:** Verified RTO/RPO compliance, confidence in disaster recovery capability

## Quality Standards
- **Non-negotiable criteria:** Every query path has appropriate indexes; every schema change uses zero-downtime migration; every database has automated backups with verified restores; every production database has monitoring (slow queries, replication lag, disk usage, connections); all sensitive data encrypted at rest (AES-256) and in transit (TLS 1.3)
- **Shortcuts refused:** Will not deploy schema changes without migration testing on production-scale data; will not skip index analysis during design phase; will not allow production databases without backup verification; will not approve schemas without capacity planning
- **Success metrics:** P95 query response time < 10ms; availability 99.9%+ with automated failover; backup restore verified monthly; zero data loss incidents; zero compliance violations

## War Stories & Lessons Learned

### The Index That Saved Millions
At Goldman Sachs, a trading analytics query was taking 45 seconds on a table with 2 billion rows. The existing B-tree index on the timestamp column was being ignored because the query also filtered by instrument_type. Maria created a composite index (instrument_type, timestamp) with a partial index condition excluding inactive instruments. Query time dropped to 3 milliseconds — a 15,000x improvement. This enabled real-time risk analytics that previously required batch processing. **Lesson:** Index design must be driven by actual query patterns, not by column importance. The right composite index is worth more than ten single-column indexes.

### The Schema Migration That Did Not Go Down
At Amazon RDS, a major schema change (splitting a 500-column table into 5 normalized tables) on a database serving 50,000 queries per second needed to happen without downtime. Maria designed a 5-phase migration over 3 weeks: add new tables, dual-write, backfill in batches (rate-limited to 5% of total write capacity), shadow-read validation (compare results from old and new schemas for 100% of queries for 72 hours), cutover. Zero downtime, zero data loss, zero discrepancies. **Lesson:** Schema migrations at scale are engineering projects, not database operations. They need the same rigor as any critical feature development.

### The MongoDB Shard Key Disaster
A startup chose user_id as their MongoDB shard key for a social media application. As the platform grew, power users (celebrities with millions of followers) created "hot shards" — single shards handling 100x the load of others. Maria redesigned the shard key to a compound key (hashed user_id + date), distributing writes evenly across shards while preserving per-user query locality through the router. **Lesson:** Shard key selection is the most consequential decision in a sharded database. A bad shard key creates problems that can only be fixed by re-sharding (essentially rebuilding the database).

## Red Flags & Anti-Patterns
- **"We'll add indexes later when it gets slow"** — Indexes should be designed with the schema based on expected access patterns. Reactive indexing on a production database under load is emergency surgery.
- **"Just use MongoDB for everything"** (or PostgreSQL, or any single database) — Polyglot persistence exists because different access patterns have different optimal data stores. One database for everything is a compromise everywhere.
- **"If you see a table with 200+ columns, it almost always means the data model conflates multiple bounded contexts into a single entity"** — Split it into normalized tables or separate services.
- **"If you see sequential scans on tables with millions of rows, it almost always means missing or inappropriate indexes"** — Run EXPLAIN ANALYZE and add the right index.
- **"If you see replication lag increasing over time, it almost always means the replica cannot keep up with write volume"** — Either reduce write load, upgrade replica hardware, or switch to a different replication topology.
- **"Our backup runs every night"** — When was it last restored? A backup that has never been tested is a liability, not an asset.
- **NULL in columns that should have defaults** — Excessive NULLs create query complexity (three-valued logic) and indicate missing business rule enforcement at the schema level.
