# AWS DynamoDB & RDS — Database Services

Two very different answers to "where does my data live," covering the two major database
paradigms AWS offers as managed services.

## DynamoDB (NoSQL)

### NoSQL

A key-value / document database — no fixed schema across rows, no SQL joins, and
(unlike a relational database) it's built from the ground up to scale horizontally to
effectively unlimited throughput and storage, trading off the rich querying a relational
database gives you for predictable, very low single-digit-millisecond latency at any
scale.

### Tables

The top-level container, roughly analogous to a SQL table, but **schemaless** beyond its
key definition — different items in the same table can have completely different sets of
attributes.

### Items

A single row/record in a table — a collection of attributes, one of which (or one pair of
which) must be the table's defined key. No upfront limit on which attributes an item can
have, as long as it includes the key.

### Attributes

A single field on an item — a name/value pair (string, number, boolean, list, map, binary,
...). Analogous to a column, except attributes aren't declared ahead of time for the whole
table — each item just carries whatever attributes it needs.

### Partition Key

The attribute DynamoDB uses to decide **which physical partition** an item is stored on —
it's hashed to distribute items evenly across partitions. This is the single most
important design decision in a DynamoDB table: a poorly chosen partition key (low
cardinality, "hot" values that get accessed way more than others) creates a hot partition
that throttles the whole table's throughput, no matter how much capacity is provisioned.

### Sort Key

An optional second part of the key — items sharing the same partition key are stored
together, ordered by sort key, which is what makes efficient range queries possible
("get all orders for customer X between date A and date B") without a full table scan.

### Use Cases

Session storage, shopping carts, gaming leaderboards, IoT telemetry ingestion — anything
needing massive, predictable-latency read/write throughput where the access patterns are
known in advance and don't need complex ad-hoc joins.

## RDS (Relational Database Service)

### Relational Database

A managed wrapper around a real, familiar SQL engine — AWS handles patching, backups, and
failover, but the engine underneath is the same SQL database you'd run yourself, with
real schemas, foreign keys, transactions, and joins.

### Supported Engines

MySQL, PostgreSQL, MariaDB, Oracle, SQL Server, and **Aurora** — AWS's own
MySQL/PostgreSQL-compatible engine, re-architected for higher throughput and faster
failover than stock MySQL/Postgres while keeping the same wire protocol and drivers.

### DB Instances

The actual running database server — sized by instance class (similar concept to EC2's
`t3`/`m5` families) plus storage type/size. Unlike DynamoDB, an RDS instance has real,
fixed compute/storage capacity that must be explicitly resized as load grows (Aurora
Serverless is the exception, scaling more dynamically).

### Security

Runs inside a VPC like EC2 — reachable only from what its Security Group allows,
typically only from application servers in the same VPC, never directly from the
internet. Encryption at rest (via KMS) and in transit (TLS) are both available and
generally expected in any real deployment.

### Backups

Automated daily snapshots plus continuous transaction-log backup, enabling **point-in-time
recovery** to any second within the retention window (up to 35 days) — not just "restore
last night's backup," but "restore to exactly 2:47pm yesterday, right before the bad
migration ran."

### Multi-AZ

A **synchronous standby replica** in a different Availability Zone, for high availability
— not for scaling reads (that's what Read Replicas are for). If the primary fails, RDS
automatically fails over to the standby, typically within a minute or two, with no manual
intervention and no data loss (synchronous replication).

### Read Replicas

**Asynchronous** copies of the database used to scale read-heavy workloads — route
reporting/analytics queries to a replica instead of the primary, keeping the primary free
for writes. Unlike a Multi-AZ standby, a Read Replica is queryable directly and can even
be promoted to a standalone writable database if needed.

### Use Cases

Anything needing real relational integrity — transactional e-commerce order data,
financial records, or any schema with genuine foreign-key relationships and a need for
complex multi-table queries that a NoSQL store can't express efficiently.
