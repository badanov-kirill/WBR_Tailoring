CREATE PROCEDURE [Warehouse].[InventoryType_Get]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	it.it_id,
			it.it_name
	FROM	Warehouse.InventoryType it