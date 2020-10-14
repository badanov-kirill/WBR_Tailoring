CREATE PROCEDURE [Products].[ClothingZone_Get]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	cz.cz_id,
			cz.cz_name
	FROM	Products.ClothingZone cz