CREATE PROCEDURE [Warehouse].[StoragePlaceType_Get]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	spt.place_type_id,
			spt.place_type_name
	FROM	Warehouse.StoragePlaceType spt
GO