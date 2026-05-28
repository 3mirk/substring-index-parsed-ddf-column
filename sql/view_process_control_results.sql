-- DSPC DDF / DDFDBP Result Parser View
-- Purpose:
--   Normalizes semi-structured DDF_Result and DDFDBP_Result strings into metric/value/verdict columns
--   for reporting in BI tools such as Power BI.
--
-- Notes:
--   - Update the AM value and view name for each lab/tool deployment.
--   - Tray/workorder translation is kept in the tray_translation CTE at the top for easier maintenance.
--   - Date/window filters should usually be applied in the consuming query/report, not hard-coded into the view.

CREATE OR REPLACE VIEW ar_database.vw_dspc_ddf_results AS
WITH tray_translation AS (
    SELECT '2100000' AS workorder, 'A1' AS vft UNION ALL
    SELECT '2200000', 'A2' UNION ALL
    SELECT '2300000', 'A3' UNION ALL
    SELECT '2400000', 'B1' UNION ALL
    SELECT '2500000', 'B2' UNION ALL
    SELECT '2600000', 'B3' UNION ALL
    SELECT '2700000', 'C1' UNION ALL
    SELECT '2800000', 'C2' UNION ALL
    SELECT '2900000', 'C3'
),

parsed AS (
    SELECT
        84 AS AM,
        r.workorder,
        COALESCE(t.vft, r.workorder) AS VFT,
        r.lnam,
        r.ErrorId,
        DATE(r.createddate) AS DateNew,
        TIME(r.createddate) AS TimeNew,
        WEEK(r.createddate) AS WeekNew,
        CONCAT('yr.', DATE_FORMAT(r.createddate, '%y'), ' wk.', WEEK(r.createddate)) AS WeekLabel,
        CONCAT(COALESCE(t.vft, r.workorder), ' ', DATE(r.createddate)) AS JoinK,

        -- DDF_Result: pre-DBP verdicts
        NULLIF(SUBSTRING_INDEX(SUBSTRING_INDEX(r.DDF_Result, 'Best Fit Tx;', -1), ';', 1), '') AS Tx_Ver_Raw,
        NULLIF(SUBSTRING_INDEX(SUBSTRING_INDEX(r.DDF_Result, 'Best Fit Ty;', -1), ';', 1), '') AS Ty_Ver_Raw,
        NULLIF(SUBSTRING_INDEX(SUBSTRING_INDEX(r.DDF_Result, 'Best Fit Rz;', -1), ';', 1), '') AS Rz_Ver_Raw,
        NULLIF(SUBSTRING_INDEX(SUBSTRING_INDEX(r.DDF_Result, 'Full Lens GMC;', -1), ';', 1), '') AS FLGMC_Ver_Raw,
        NULLIF(SUBSTRING_INDEX(SUBSTRING_INDEX(r.DDF_Result, 'Center GMC;', -1), ';', 1), '') AS CGMC_Ver_Raw,
        NULLIF(SUBSTRING_INDEX(SUBSTRING_INDEX(r.DDF_Result, 'Center Power Av;', -1), ';', 1), '') AS CPA_Ver_Raw,

        -- DDF_Result: pre-DBP values
        NULLIF(SUBSTRING_INDEX(SUBSTRING_INDEX(SUBSTRING_INDEX(r.DDF_Result, 'Best Fit Tx;', -1), ';', 2), ';', -1), '') AS Tx_Raw,
        NULLIF(SUBSTRING_INDEX(SUBSTRING_INDEX(SUBSTRING_INDEX(r.DDF_Result, 'Best Fit Ty;', -1), ';', 2), ';', -1), '') AS Ty_Raw,
        NULLIF(SUBSTRING_INDEX(SUBSTRING_INDEX(SUBSTRING_INDEX(r.DDF_Result, 'Best Fit Rz;', -1), ';', 2), ';', -1), '') AS Rz_Raw,
        NULLIF(SUBSTRING_INDEX(SUBSTRING_INDEX(SUBSTRING_INDEX(r.DDF_Result, 'Full Lens GMC;', -1), ';', 2), ';', -1), '') AS FLGMC_Raw,
        NULLIF(SUBSTRING_INDEX(SUBSTRING_INDEX(SUBSTRING_INDEX(r.DDF_Result, 'Center GMC;', -1), ';', 2), ';', -1), '') AS CGMC_Raw,
        NULLIF(SUBSTRING_INDEX(SUBSTRING_INDEX(SUBSTRING_INDEX(r.DDF_Result, 'Center Power Av;', -1), ';', 2), ';', -1), '') AS CPA_Raw,

        -- DDFDBP_Result: post-DBP verdicts
        CASE WHEN LOCATE('Best Fit Tx;', r.DDFDBP_Result) > 0
            THEN NULLIF(SUBSTRING_INDEX(SUBSTRING_INDEX(r.DDFDBP_Result, 'Best Fit Tx;', -1), ';', 1), '')
        END AS Tx_DBP_Ver_Raw,
        CASE WHEN LOCATE('Best Fit Ty;', r.DDFDBP_Result) > 0
            THEN NULLIF(SUBSTRING_INDEX(SUBSTRING_INDEX(r.DDFDBP_Result, 'Best Fit Ty;', -1), ';', 1), '')
        END AS Ty_DBP_Ver_Raw,
        CASE WHEN LOCATE('Best Fit Rz;', r.DDFDBP_Result) > 0
            THEN NULLIF(SUBSTRING_INDEX(SUBSTRING_INDEX(r.DDFDBP_Result, 'Best Fit Rz;', -1), ';', 1), '')
        END AS Rz_DBP_Ver_Raw,
        CASE WHEN LOCATE('Full Lens GMC;', r.DDFDBP_Result) > 0
            THEN NULLIF(SUBSTRING_INDEX(SUBSTRING_INDEX(r.DDFDBP_Result, 'Full Lens GMC;', -1), ';', 1), '')
        END AS FLGMC_DBP_Ver_Raw,
        CASE WHEN LOCATE('Center GMC;', r.DDFDBP_Result) > 0
            THEN NULLIF(SUBSTRING_INDEX(SUBSTRING_INDEX(r.DDFDBP_Result, 'Center GMC;', -1), ';', 1), '')
        END AS CGMC_DBP_Ver_Raw,
        CASE WHEN LOCATE('Center Power Av;', r.DDFDBP_Result) > 0
            THEN NULLIF(SUBSTRING_INDEX(SUBSTRING_INDEX(r.DDFDBP_Result, 'Center Power Av;', -1), ';', 1), '')
        END AS CPA_DBP_Ver_Raw,

        -- DDFDBP_Result: post-DBP values
        CASE WHEN LOCATE('Best Fit Tx;', r.DDFDBP_Result) > 0
            THEN NULLIF(SUBSTRING_INDEX(SUBSTRING_INDEX(SUBSTRING_INDEX(r.DDFDBP_Result, 'Best Fit Tx;', -1), ';', 2), ';', -1), '')
        END AS Tx_DBP_Raw,
        CASE WHEN LOCATE('Best Fit Ty;', r.DDFDBP_Result) > 0
            THEN NULLIF(SUBSTRING_INDEX(SUBSTRING_INDEX(SUBSTRING_INDEX(r.DDFDBP_Result, 'Best Fit Ty;', -1), ';', 2), ';', -1), '')
        END AS Ty_DBP_Raw,
        CASE WHEN LOCATE('Best Fit Rz;', r.DDFDBP_Result) > 0
            THEN NULLIF(SUBSTRING_INDEX(SUBSTRING_INDEX(SUBSTRING_INDEX(r.DDFDBP_Result, 'Best Fit Rz;', -1), ';', 2), ';', -1), '')
        END AS Rz_DBP_Raw,
        CASE WHEN LOCATE('Full Lens GMC;', r.DDFDBP_Result) > 0
            THEN NULLIF(SUBSTRING_INDEX(SUBSTRING_INDEX(SUBSTRING_INDEX(r.DDFDBP_Result, 'Full Lens GMC;', -1), ';', 2), ';', -1), '')
        END AS FLGMC_DBP_Raw,
        CASE WHEN LOCATE('Center GMC;', r.DDFDBP_Result) > 0
            THEN NULLIF(SUBSTRING_INDEX(SUBSTRING_INDEX(SUBSTRING_INDEX(r.DDFDBP_Result, 'Center GMC;', -1), ';', 2), ';', -1), '')
        END AS CGMC_DBP_Raw,
        CASE WHEN LOCATE('Center Power Av;', r.DDFDBP_Result) > 0
            THEN NULLIF(SUBSTRING_INDEX(SUBSTRING_INDEX(SUBSTRING_INDEX(r.DDFDBP_Result, 'Center Power Av;', -1), ';', 2), ';', -1), '')
        END AS CPA_DBP_Raw

    FROM ar_database.results r
    LEFT JOIN tray_translation t
        ON r.workorder = t.workorder
    WHERE r.lnam IN ('R07', 'DSPC ART', 'DSPC_ART')
)

SELECT
    AM,
    workorder,
    VFT,
    lnam,
    ErrorId,
    DateNew,
    TimeNew,
    WeekNew,
    WeekLabel,
    JoinK,

    CAST(Tx_Ver_Raw AS UNSIGNED) AS Tx_Ver,
    CAST(Ty_Ver_Raw AS UNSIGNED) AS Ty_Ver,
    CAST(Rz_Ver_Raw AS UNSIGNED) AS Rz_Ver,
    CAST(FLGMC_Ver_Raw AS UNSIGNED) AS FLGMC_Ver,
    CAST(CGMC_Ver_Raw AS UNSIGNED) AS CGMC_Ver,
    CAST(CPA_Ver_Raw AS UNSIGNED) AS CPA_Ver,

    CAST(Tx_Raw AS DECIMAL(8,3)) AS Tx,
    CAST(Ty_Raw AS DECIMAL(8,3)) AS Ty,
    CAST(Rz_Raw AS DECIMAL(8,3)) AS Rz,
    CAST(FLGMC_Raw AS DECIMAL(8,3)) AS FLGMC,
    CAST(CGMC_Raw AS DECIMAL(8,3)) AS CGMC,
    CAST(CPA_Raw AS DECIMAL(8,3)) AS CPA,

    CAST(Tx_DBP_Ver_Raw AS UNSIGNED) AS Tx_DBP_Ver,
    CAST(Ty_DBP_Ver_Raw AS UNSIGNED) AS Ty_DBP_Ver,
    CAST(Rz_DBP_Ver_Raw AS UNSIGNED) AS Rz_DBP_Ver,
    CAST(FLGMC_DBP_Ver_Raw AS UNSIGNED) AS FLGMC_DBP_Ver,
    CAST(CGMC_DBP_Ver_Raw AS UNSIGNED) AS CGMC_DBP_Ver,
    CAST(CPA_DBP_Ver_Raw AS UNSIGNED) AS CPA_DBP_Ver,

    CAST(Tx_DBP_Raw AS DECIMAL(8,3)) AS Tx_DBP,
    CAST(Ty_DBP_Raw AS DECIMAL(8,3)) AS Ty_DBP,
    CAST(Rz_DBP_Raw AS DECIMAL(8,3)) AS Rz_DBP,
    CAST(FLGMC_DBP_Raw AS DECIMAL(8,3)) AS FLGMC_DBP,
    CAST(CGMC_DBP_Raw AS DECIMAL(8,3)) AS CGMC_DBP,
    CAST(CPA_DBP_Raw AS DECIMAL(8,3)) AS CPA_DBP,

    COALESCE(CAST(Tx_Ver_Raw AS UNSIGNED), 0)
        + COALESCE(CAST(Ty_Ver_Raw AS UNSIGNED), 0)
        + COALESCE(CAST(Rz_Ver_Raw AS UNSIGNED), 0)
        + COALESCE(CAST(FLGMC_Ver_Raw AS UNSIGNED), 0)
        + COALESCE(CAST(CGMC_Ver_Raw AS UNSIGNED), 0)
        + COALESCE(CAST(CPA_Ver_Raw AS UNSIGNED), 0) AS Overall_Ver_Sum

FROM parsed;
