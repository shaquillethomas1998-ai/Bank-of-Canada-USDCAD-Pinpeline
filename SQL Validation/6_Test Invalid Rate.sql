DECLARE @FixtureRunId uniqueidentifier = NEWID();

EXEC dbo.LoadUsdCad
    @ObservationsJson = N'[{"d":"2025-01-02","FXUSDCAD":{"v":"bad-rate"}}]',
    @PipelineRunId = @FixtureRunId;

SELECT
    r.PipelineRunId,
    r.RawObservationDate,
    r.RawRate,
    r.RejectReason,
    e.Rate AS StoredRate
FROM dbo.ExchangeRateReject AS r
JOIN dbo.ExchangeRate AS e
    ON e.SeriesCode = r.SeriesCode
   AND e.ObservationDate = TRY_CONVERT(date, r.RawObservationDate, 23)
WHERE r.PipelineRunId = @FixtureRunId;