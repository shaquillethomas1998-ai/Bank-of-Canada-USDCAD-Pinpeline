SELECT ObservationDate, Rate
FROM dbo.ExchangeRate
WHERE SeriesCode = 'FXUSDCAD'
  AND ObservationDate BETWEEN '2025-01-02' AND '2025-01-06'
ORDER BY ObservationDate;