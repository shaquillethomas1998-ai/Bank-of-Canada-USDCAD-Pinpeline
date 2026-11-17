CREATE OR ALTER PROCEDURE dbo.CheckUsdCadFreshness
    @CheckDate varchar(10)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @AsOfDate date = TRY_CONVERT(date, @CheckDate, 23);
    DECLARE @ExpectedDate date;
    DECLARE @LatestStoredDate date;
    DECLARE @ErrorMessage nvarchar(2048);

    IF @AsOfDate IS NULL OR @CheckDate <> CONVERT(char(10), @AsOfDate, 23)
        THROW 50002, 'CheckDate must use yyyy-MM-dd.', 1;

    -- Extend the reviewed calendar before running checks in 2027.
    IF @AsOfDate NOT BETWEEN '2026-11-11' AND '2026-12-31'
        THROW 50003, 'Check date is outside the reviewed Bank holiday calendar.', 1;

    SELECT @ExpectedDate = MAX(d.CandidateDate)
    FROM (VALUES (0), (1), (2), (3), (4), (5), (6)) AS n(DaysBack)
    CROSS APPLY (VALUES (DATEADD(day, -n.DaysBack, @AsOfDate))) AS d(CandidateDate)
    WHERE d.CandidateDate >= '2026-11-10'
      AND DATEDIFF(day, '19000101', d.CandidateDate) % 7 BETWEEN 0 AND 4
      AND d.CandidateDate NOT IN ('2026-11-11', '2026-12-25', '2026-12-28');

    SELECT @LatestStoredDate = MAX(ObservationDate)
    FROM dbo.ExchangeRate
    WHERE SeriesCode = 'FXUSDCAD'
      AND ObservationDate <= @AsOfDate;

    IF @LatestStoredDate IS NULL OR @LatestStoredDate <> @ExpectedDate
    BEGIN
        SET @ErrorMessage = CONCAT(
            'USD/CAD freshness check failed. Expected ',
            CONVERT(char(10), @ExpectedDate, 23),
            '. Latest stored date: ',
            COALESCE(CONVERT(char(10), @LatestStoredDate, 23), 'none'),
            '.'
        );
        THROW 50004, @ErrorMessage, 1;
    END;
END;