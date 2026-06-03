# AWS DMS Notes

These notes focus on the AWS DMS part of the project: what DMS does, how it connected to the source database, how it wrote files to S3, and what needed to be configured correctly.

## What AWS DMS Does

AWS DMS means AWS Database Migration Service.

DMS helps move data from one data store to another. In this project, DMS moved data from:

```text
Amazon RDS for MySQL
```

to:

```text
Amazon S3
```

The source was a relational database. The target was object storage.

That means DMS took database table data and wrote it out as files in S3.

## What DMS Did in This Project

In this project, DMS performed two main jobs:

| DMS Job | What It Means |
|---|---|
| Full load | Copy the existing rows from the source tables |
| CDC | Continue capturing new database changes after the first load |

The DMS task copied data from the source MySQL schema:

```text
dms_source_db
```

The tables were:

```text
customers
products
orders
```

DMS wrote output files into:

```text
s3://dms-source-retail-jenny-us-east-2/dms-output/
```

DBeaver was used as the SQL client for the source database work. It connected to the RDS MySQL instance so the seed script could be run, source tables could be checked, and validation queries could confirm the data before DMS migrated it.

## Full Load

Full load means the first copy of existing data.

For this project, the source database already had sample rows in the `customers`, `products`, and `orders` tables.

When the DMS task started, it copied those existing rows into S3.

Example idea:

```text
customers table in MySQL
    ↓
DMS full load
    ↓
customers output file in S3
```

## CDC

CDC means change data capture.

After the full load, DMS can continue watching the database for new changes.

Examples of CDC changes:

```text
INSERT new customer
UPDATE order status
DELETE old record
```

For this project, the DMS task reached:

```text
Load complete, replication ongoing
```

That means the first copy finished, and DMS was still running to capture ongoing changes.

## DMS Replication Instance

The DMS replication instance is the compute resource that runs the migration task.

A simple way to think about it:

```text
DMS replication instance = the worker that moves the data
```

It needs network access to the source database and permissions to write to the target.

In this project, the replication instance had to reach the RDS MySQL database on:

```text
Port 3306
```

## DMS Source Endpoint

The source endpoint tells DMS how to connect to the source database.

For this project, the source endpoint connected to:

```text
Amazon RDS for MySQL
```

A successful source endpoint test proved that DMS could reach and authenticate to the MySQL database.

## DMS Target Endpoint

The target endpoint tells DMS where to write the migrated data.

For this project, the target endpoint was Amazon S3.

DMS wrote files under:

```text
s3://dms-source-retail-jenny-us-east-2/dms-output/
```

A successful target endpoint test proved that DMS had the permissions and configuration needed to write to S3.

## Table Mapping

Table mapping tells DMS which schemas and tables to include.

This was one of the most important troubleshooting points in the project.

The working MySQL schema was:

```text
dms_source_db
```

The DMS table mapping had to reference that exact schema name.

If the mapping points to the wrong schema, DMS may connect successfully but still fail to find tables.

That is what caused the original issue:

```text
No tables were found at task initialization
```

## Why the Schema Name Mattered

In MySQL, the database name and schema name are often treated as the same thing.

So when DMS looked for tables, it needed the actual source database/schema name.

Working schema:

```text
dms_source_db
```

Tables inside it:

```text
dms_source_db.customers
dms_source_db.products
dms_source_db.orders
```

If DMS was told to look under another schema name, it would not find the tables.

## Source Database CDC Settings

For MySQL CDC, binary logging needs to be enabled because DMS uses database logs to capture changes.

The SQL seed script included checks such as:

```sql
SHOW VARIABLES LIKE 'log_bin';
SHOW VARIABLES LIKE 'binlog_format';
SHOW VARIABLES LIKE 'binlog_row_image';
```

For CDC, the important idea is:

```text
DMS needs the database change logs to know what changed after the full load.
```

The script also included:

```sql
CALL mysql.rds_set_configuration('binlog retention hours', 24);
```

That helps keep binary logs available long enough for short CDC testing.

## DMS Output in S3

DMS wrote output files into the source S3 bucket under:

```text
dms-output/
```

Example pattern:

```text
dms-output/dms_source_db/customers/LOAD00000001.csv
dms-output/dms_source_db/products/LOAD00000001.csv
dms-output/dms_source_db/orders/LOAD00000001.csv
```

Those new S3 files then started the second half of the project: the event-driven copy to another region.

## How DMS Connected to the Rest of the Project

DMS did not copy files to the final target bucket directly in this project.

DMS wrote files to the source S3 bucket.

Then the event-driven flow handled the cross-region copy:

```text
DMS writes file to source S3
    ↓
S3 object-created event
    ↓
SNS
    ↓
SQS
    ↓
Lambda
    ↓
Target S3 bucket
```

So DMS handled the database migration part.

Lambda handled the cross-region file copy part.

## Troubleshooting Summary

| Issue | Cause | Fix |
|---|---|---|
| DMS task found no tables | Table mapping used the wrong schema name | Updated mapping to `dms_source_db` |
| Source endpoint needed access to RDS | Security group rule needed the actual source security group ID | Allowed MySQL access on port `3306` |
| Target endpoint setup was confusing | AWS console layout differed from expected steps | Selected the S3 bucket and DMS IAM role in the updated UI |
| CDC needed database logs | DMS needs MySQL binary logs for change capture | Checked CDC-related MySQL settings |

## Key DMS Vocabulary

| Term | Meaning |
|---|---|
| DMS | AWS Database Migration Service |
| Full load | Initial copy of existing source data |
| CDC | Change data capture for ongoing changes |
| Source endpoint | DMS connection configuration for the source |
| Target endpoint | DMS connection configuration for the target |
| Replication instance | DMS compute resource that runs the task |
| Migration task | DMS job that performs the data movement |
| Table mapping | Rules that tell DMS which schemas/tables to include |
| Binary logs | MySQL logs used to track database changes |
| Schema | Database namespace that contains tables |

## Main Takeaway

AWS DMS handled the database-to-S3 part of the project.

The most important DMS lesson from this build was that connection tests are only part of the setup. The source endpoint can connect successfully, but the migration task can still fail if the table mapping does not match the real source schema.

For this project, the key fix was making sure DMS used:

```text
dms_source_db
```

as the source schema.
