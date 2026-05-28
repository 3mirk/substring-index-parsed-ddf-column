# Schema Notes

## Source table

Default source table used by the view:

```sql
ar_database.results
```

Update this schema/table name if deploying in a different environment.

## Required source columns

| Column | Purpose |
|---|---|
| `workorder` | Tray/workorder code used for line translation |
| `lnam` | Inspection/source filter field |
| `ErrorId` | Source inspection record identifier |
| `createddate` | Inspection timestamp |
| `DDF_Result` | Pre-DBP semicolon-delimited inspection result string |
| `DDFDBP_Result` | Post-DBP semicolon-delimited inspection result string |

## Tray translation

The view contains a `tray_translation` CTE at the top of the SQL file.

Example:

```sql
SELECT '2100000' AS workorder, 'A1' AS vft UNION ALL
SELECT '2200000', 'A2'
```

Update these values to match the target production environment.

## Parsed pre-DBP output columns

| Metric | Verdict column | Value column |
|---|---|---|
| Best Fit Tx | `Tx_Ver` | `Tx` |
| Best Fit Ty | `Ty_Ver` | `Ty` |
| Best Fit Rz | `Rz_Ver` | `Rz` |
| Full Lens GMC | `FLGMC_Ver` | `FLGMC` |
| Center GMC | `CGMC_Ver` | `CGMC` |
| Center Power Average | `CPA_Ver` | `CPA` |

## Parsed post-DBP output columns

| Metric | Verdict column | Value column |
|---|---|---|
| Best Fit Tx | `Tx_DBP_Ver` | `Tx_DBP` |
| Best Fit Ty | `Ty_DBP_Ver` | `Ty_DBP` |
| Best Fit Rz | `Rz_DBP_Ver` | `Rz_DBP` |
| Full Lens GMC | `FLGMC_DBP_Ver` | `FLGMC_DBP` |
| Center GMC | `CGMC_DBP_Ver` | `CGMC_DBP` |
| Center Power Average | `CPA_DBP_Ver` | `CPA_DBP` |

## Derived fields

| Column | Description |
|---|---|
| `VFT` | Readable production line label from tray/workorder translation |
| `DateNew` | Date portion of `createddate` |
| `TimeNew` | Time portion of `createddate` |
| `WeekNew` | Week number from `createddate` |
| `WeekLabel` | Formatted year/week label |
| `JoinK` | Concatenated VFT/date key for downstream reporting |
| `Overall_Ver_Sum` | Sum of pre-DBP metric verdicts |

## Notes

- The parser assumes the result string labels are consistent.
- Missing post-DBP metrics are returned as `NULL`.
- Date filters should usually be applied in Power BI or in a consuming query, not hard-coded inside the view.
- The view is intended as a SQL transformation layer for reporting and analytics, not as a transactional table.
