CREATE PROCEDURE [Warehouse].[ZoneOfResponse_Get]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	zor.zor_id,
			zor.zor_name,
			zor.office_id
	FROM	Warehouse.ZoneOfResponse zor
GO