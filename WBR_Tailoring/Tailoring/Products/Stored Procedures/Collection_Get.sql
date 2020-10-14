CREATE PROCEDURE [Products].[Collection_Get]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	c.collection_id,
			c.collection_name,
			c.collection_year
	FROM	Products.[Collection] c
	WHERE	c.is_deleted = 0
	ORDER BY c.collection_id DESC