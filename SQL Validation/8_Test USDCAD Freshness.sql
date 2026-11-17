;WITH TestDates AS
(
    SELECT CAST(CheckDate AS date) AS CheckDate
    FROM (VALUES ('2026-11-11'), ('2026-11-13'), ('2026-11-15')) AS t(CheckDate)
),
BankHolidays AS
(
    SELECT CAST(HolidayDate AS date) AS HolidayDate
    FROM (VALUES ('2026-11-11'), ('2026-12-25'), ('2026-12-28')) AS h(HolidayDate)
)
SELECT
    t.CheckDate,
    expected.ExpectedDate,
    stored.LatestStoredDate,
    CASE
        WHEN stored.LatestStoredDate = expected.ExpectedDate THEN 'Fresh'
        ELSE 'Missing expected observation'
    END AS FreshnessStatus
FROM TestDates AS t
CROSS APPLY
(
    SELECT MAX(d.CandidateDate) AS ExpectedDate
    FROM (VALUES (0), (1), (2), (3), (4), (5), (6)) AS n(DaysBack)
    CROSS APPLY (VALUES (DATEADD(day, -n.DaysBack, t.CheckDate))) AS d(CandidateDate)
    -- January 1, 1900 was a Monday. Remainders 0–4 are Monday–Friday.
    WHERE DATEDIFF(day, '19000101', d.CandidateDate) % 7 BETWEEN 0 AND 4
      AND NOT EXISTS
      (
          SELECT 1
          FROM BankHolidays AS h
          WHERE h.HolidayDate = d.CandidateDate
      )
) AS expected
CROSS APPLY
(
    SELECT MAX(ObservationDate) AS LatestStoredDate
    FROM dbo.ExchangeRate
    WHERE SeriesCode = 'FXUSDCAD'
      AND ObservationDate <= t.CheckDate
) AS stored
ORDER BY t.CheckDate;