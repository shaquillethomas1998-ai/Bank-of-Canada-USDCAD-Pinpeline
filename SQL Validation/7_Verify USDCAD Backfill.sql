SELECT
    COUNT(*) AS ObservationCount,
    MIN(ObservationDate) AS FirstObservation,
    MAX(ObservationDate) AS LastObservation
FROM dbo.ExchangeRate
WHERE SeriesCode = 'FXUSDCAD'
  AND ObservationDate BETWEEN '2025-11-16' AND '2026-11-15';