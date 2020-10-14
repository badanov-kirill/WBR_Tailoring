CREATE PROCEDURE [Products].[Kind_Get]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	k.kind_id,
			k.kind_name
	FROM	Products.Kind k
	WHERE	k.isdeleted = 0