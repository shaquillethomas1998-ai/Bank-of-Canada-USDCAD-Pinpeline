IF DATABASE_PRINCIPAL_ID(N'adf-boc-fx-dev-01') IS NULL
    CREATE USER [adf-boc-fx-dev-01] FROM EXTERNAL PROVIDER;

GRANT EXECUTE ON OBJECT::dbo.LoadUsdCad TO [adf-boc-fx-dev-01];