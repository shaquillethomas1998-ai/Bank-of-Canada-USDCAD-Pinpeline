GRANT EXECUTE ON OBJECT::dbo.CheckUsdCadFreshness TO [adf-boc-fx-dev-01];

EXEC dbo.CheckUsdCadFreshness @CheckDate = '2026-11-15';