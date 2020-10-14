CREATE PROCEDURE [Products].[Direction_Get]
	@is_deleted BIT = 0
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	d.direction_id,
			d.direction_name
	FROM	Products.Direction d
	WHERE	@is_deleted IS NULL
			OR	d.is_deleted = @is_deleted
