IF OBJECT_ID(N'dbo.ExchangeRate', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ExchangeRate
    (
        SeriesCode      varchar(16)   NOT NULL,
        ObservationDate date          NOT NULL,
        Rate            decimal(19,8) NOT NULL,

        CONSTRAINT PK_ExchangeRate
            PRIMARY KEY (SeriesCode, ObservationDate),

        CONSTRAINT CK_ExchangeRate_PositiveRate
            CHECK (Rate > 0)
    );
END;

SELECT DB_NAME() AS DatabaseName, COUNT(*) AS ObservationCount
FROM dbo.ExchangeRate;