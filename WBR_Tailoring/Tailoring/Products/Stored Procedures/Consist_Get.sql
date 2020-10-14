CREATE PROCEDURE [Products].[Consist_Get]
	@is_deleted BIT = 0
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	c.consist_id,
			c.consist_name
	FROM	Products.Consist c
	WHERE	@is_deleted IS NULL
			OR	c.is_deleted = @is_deleted   