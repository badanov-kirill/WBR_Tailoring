CREATE PROCEDURE [Products].[ProdArticleSyncQueue_Get]
AS
	SET NOCOUNT ON
	
	SELECT	pasq.pa_id,
			CAST(CAST(pasq.rv AS BIGINT) AS VARCHAR(20)) rv_bigint
	FROM	Products.ProdArticleSyncQueue pasq
	WHERE	pasq.spec_uid IS NULL