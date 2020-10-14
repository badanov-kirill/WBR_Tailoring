CREATE PROCEDURE [Material].[ClothColor_Get]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	cc.color_id,
			cc.color_name,
			cc.color_cod
	FROM	Material.ClothColor cc