CREATE PROCEDURE [Products].[Color_Get]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	c.color_cod,
			c.color_cod_parent,
			c.color_name
	FROM	Products.Color c
	WHERE	c.isdeleted = 0