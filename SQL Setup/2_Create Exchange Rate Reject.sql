IF OBJECT_ID(N'dbo.ExchangeRateReject', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ExchangeRateReject
    (
        RejectId           bigint IDENTITY(1,1) PRIMARY KEY,
        PipelineRunId      uniqueidentifier NOT NULL,
        SeriesCode         varchar(16)      NOT NULL,
        RawObservationDate nvarchar(4000)   NULL,
        RawRate            nvarchar(4000)   NULL,
        RejectReason       varchar(100)     NOT NULL,
        RejectedAtUtc      datetime2(0)     NOT NULL
            DEFAULT SYSUTCDATETIME()
    );
END;