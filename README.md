# Nested SUBSTRING_INDEX DDF Parser 
 
SQL view for parsing semi-structured DSPC inspection result strings into structured measurement and verdict columns. The view takes `DDF_Result` and `DDFDBP_Result` columns and splits them into individual columns for each measurement criteria, along with their corresponding verdict columns. Query output feeds a Power BI data model for process control monitoring, failure analysis, and station-level quality reporting.

## What this does

In manufacturing inspection systems, detailed measurement results are sometimes stored as long semicolon-delimited text strings instead of normalized columns. A single `DDF_Result` field may contain multiple metrics, where each metric has both a verdict and a measured value.

This SQL view solves that by extracting each named metric from the result string and converting it into a reporting-friendly table structure.

It parses pre-deblock results from `DDF_Result` and post-deblock results from `DDFDBP_Result`, producing one row per inspection record with dedicated columns. The result is a clean SQL view that can be consumed directly by Power BI or another reporting layer.

## Result parsing flow

```text
DDF_Result string
      ↓
[label lookup by metric name]
      ↓
extract verdict + value
      ↓
cast to numeric fields
      ↓
Power BI reporting view
```

Example source pattern:

```text
Best Fit Tx;0;0.012;
Best Fit Ty;0;-0.004;
Best Fit Rz;1;0.081;
Full Lens GMC;0;0.034;
Center GMC;0;0.028;
Center Power Av;0;0.015;
```

Example parsed output:

```text
Tx_Ver | Tx     | Ty_Ver | Ty      | Rz_Ver | Rz
0      | 0.012  | 0      | -0.004  | 1      | 0.081
```

## Production pipeline

```text
[DDF_Result]      → [pre-DBP parser]  → Tx, Ty, Rz, FLGMC, CGMC, CPA
[DDFDBP_Result]   → [post-DBP parser] → FLGMC_DBP, CGMC_DBP, CPA_DBP
[workorder/tray]  → [line mapping]    → VFT / production line label
```

The view also contains a tray/workorder translation list at the top of the query. This maps production workorder codes to readable line labels such as A1, A2, A3, B1, B2, B3, C1, C2, and C3.

## Key SQL technique

The core technique uses nested `SUBSTRING_INDEX` calls to locate a metric by name, then split out the verdict and value fields that follow it.

```sql
-- Extract verdict for Best Fit Tx
SUBSTRING_INDEX(
    SUBSTRING_INDEX(DDF_Result, 'Best Fit Tx;', -1),
    ';',
    1
) AS Tx_Ver
```

To extract the measured value instead of the verdict, the query takes the second semicolon-delimited element after the metric label:

```sql
-- Extract value for Best Fit Tx
SUBSTRING_INDEX(
    SUBSTRING_INDEX(
        SUBSTRING_INDEX(DDF_Result, 'Best Fit Tx;', -1),
        ';',
        2
    ),
    ';',
    -1
) AS Tx
```

The final view casts verdict fields as integers and measurement fields as decimals so they can be used directly in BI measures, slicers, and visuals.

## Database

MySQL / MariaDB style SQL.

The query uses:

- `CREATE OR REPLACE VIEW`
- `WITH` common table expressions
- `SUBSTRING_INDEX`
- `DATE()`
- `TIME()`
- `WEEK()`
- `DATE_FORMAT()`
- `CAST(... AS UNSIGNED)`
- `CAST(... AS DECIMAL(...))`

The query will not run as-is on SQL Server, PostgreSQL, or IBM Informix without syntax adaptation.

Schema names, table names, line mappings, and station identifiers in this repository should be adapted to the target environment before deployment.

## Files

| File | Description |
|---|---|
| `view_process_control_results.sql` | Main SQL view that parses DDF and DDFDBP result strings into structured metric columns |
| `sql/schema_notes.md` | Table, column, and output field reference |

