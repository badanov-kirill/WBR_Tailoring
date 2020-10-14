CREATE PROCEDURE [Warehouse].[StoragePlace_GetStage]
	@office_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	DISTINCT sp.stage
	FROM	Warehouse.StoragePlace sp   
			INNER JOIN	Warehouse.ZoneOfResponse zor
				ON	zor.zor_id = sp.zor_id
	WHERE	zor.office_id = @office_id
			AND	sp.is_deleted = 0