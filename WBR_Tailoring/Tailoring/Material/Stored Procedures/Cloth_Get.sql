CREATE PROCEDURE [Material].[Cloth_Get]
	@is_deleted BIT = NULL,
	@cloth_type_id INT = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	c.cloth_id,
			c.cloth_name,
			c.is_deleted,
			c.ct_id,
			ct.ct_name
	FROM	Material.Cloth c   
			INNER JOIN	Material.ClothType ct
				ON	ct.ct_id = c.ct_id
	WHERE	(@is_deleted IS NULL OR c.is_deleted = @is_deleted)
			AND	(@cloth_type_id IS NULL OR c.ct_id = @cloth_type_id)