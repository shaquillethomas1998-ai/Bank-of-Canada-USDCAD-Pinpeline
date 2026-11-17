CREATE OR ALTER PROCEDURE dbo.LoadUsdCad
    @ObservationsJson nvarchar(max),
    @PipelineRunId uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF ISNULL(ISJSON(@ObservationsJson, ARRAY), 0) <> 1
        THROW 50001, 'Expected the Valet observations array.', 1;

    ;WITH Parsed AS
    (
        SELECT
            RawObservationDate,
            RawRate,
            TRY_CONVERT(date, RawObservationDate, 23) AS ObservationDate,
            TRY_CONVERT(decimal(19,8), NULLIF(TRIM(RawRate), N'')) AS Rate
        FROM OPENJSON(@ObservationsJson)
        WITH
        (
            RawObservationDate nvarchar(4000) '$.d',
            RawRate            nvarchar(4000) '$.FXUSDCAD.v'
        )
    ),
    Counted AS
    (
        SELECT *,
            COUNT(*) OVER (PARTITION BY ObservationDate) AS RowsForDate
        FROM Parsed
    )
    SELECT
        RawObservationDate,
        RawRate,
        ObservationDate,
        Rate,
        CASE
            WHEN ObservationDate IS NULL
                OR RawObservationDate <> CONVERT(char(10), ObservationDate, 23)
                THEN 'Missing or invalid observation date'
            WHEN NULLIF(TRIM(RawRate), N'') IS NULL THEN 'Missing rate'
            WHEN Rate IS NULL THEN 'Rate is not a valid decimal'
            WHEN Rate <= 0 THEN 'Rate must be positive'
            WHEN RowsForDate > 1 THEN 'Duplicate date in source payload'
        END AS RejectReason
    INTO #Validated
    FROM Counted;

    BEGIN TRANSACTION;

    -- Rebuild this run's rejection records if the activity retries.
    DELETE FROM dbo.ExchangeRateReject
    WHERE PipelineRunId = @PipelineRunId
      AND SeriesCode = 'FXUSDCAD';

    INSERT INTO dbo.ExchangeRateReject
        (PipelineRunId, SeriesCode, RawObservationDate, RawRate, RejectReason)
    SELECT
        @PipelineRunId, 'FXUSDCAD', RawObservationDate, RawRate, RejectReason
    FROM #Validated
    WHERE RejectReason IS NOT NULL;

    MERGE dbo.ExchangeRate WITH (HOLDLOCK) AS target
    USING
    (
        SELECT ObservationDate, Rate
        FROM #Validated
        WHERE RejectReason IS NULL
    ) AS source
        ON target.SeriesCode = 'FXUSDCAD'
       AND target.ObservationDate = source.ObservationDate
    WHEN MATCHED AND target.Rate <> source.Rate THEN
        UPDATE SET Rate = source.Rate
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (SeriesCode, ObservationDate, Rate)
        VALUES ('FXUSDCAD', source.ObservationDate, source.Rate);

    COMMIT TRANSACTION;
END;