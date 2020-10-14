CREATE PROCEDURE [Warehouse].[StoragePlace_GetStreet]
	@office_id INT,
	@stage INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	DISTINCT sp.street
	FROM	Warehouse.StoragePlace sp   
			INNER JOIN	Warehouse.ZoneOfResponse zor
				ON	zor.zor_id = sp.zor_id
	WHERE	zor.office_id = @office_id
			AND	sp.stage = @stage
			AND	sp.is_deleted = 0