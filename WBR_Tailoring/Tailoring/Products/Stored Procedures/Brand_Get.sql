CREATE PROCEDURE [Products].[Brand_Get]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	b.brand_id,
			b.brand_name,
			b.erp_id
	FROM	Products.Brand b