CREATE PROCEDURE [Products].[ProductType_Get]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT pt.pt_id,
	       pt.pt_name,
	       pt.pt_rate
	FROM   Products.ProductType pt
	