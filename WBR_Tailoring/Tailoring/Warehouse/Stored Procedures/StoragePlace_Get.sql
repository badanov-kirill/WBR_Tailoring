CREATE PROCEDURE [Warehouse].[StoragePlace_Get]
	@place_id INT = NULL,
	@stage INT = NULL,
	@street INT = NULL,
	@section INT = NULL,
	@rack INT = NULL,
	@field INT = NULL,
	@is_deleted BIT = 0,
	@place_type_id INT = NULL,
	@zor_id INT = NULL,
	@office_id INT = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	sp.place_id,
			sp.place_name,
			sp.stage,
			sp.street,
			sp.section,
			sp.rack,
			sp.field,
			sp.is_deleted,
			sp.place_type_id,
			spt.place_type_name,
			sp.zor_id,
			zor.zor_name,
			zor.office_id,
			os.office_name
	FROM	Warehouse.StoragePlace sp   
			INNER JOIN	Warehouse.StoragePlaceType spt
				ON	spt.place_type_id = sp.place_type_id   
			INNER JOIN	Warehouse.ZoneOfResponse zor
				ON	zor.zor_id = sp.zor_id
			LEFT JOIN Settings.OfficeSetting os
				ON zor.office_id = os.office_id
	WHERE	(@place_id IS NULL OR sp.place_id = @place_id)
			AND	(@stage IS NULL OR sp.stage = @stage)
			AND	(@street IS NULL OR sp.street = @street)
			AND	(@rack IS NULL OR sp.rack = @rack)
			AND	(@section IS NULL OR sp.section = @section)
			AND	(@field IS NULL OR sp.field = @field)
			AND	(@is_deleted IS NULL OR sp.is_deleted = @is_deleted)
			AND	(@place_type_id IS NULL OR sp.place_type_id = @place_type_id)
			AND	(@zor_id IS NULL OR sp.zor_id = @zor_id)
			AND	(@office_id IS NULL OR zor.office_id = @office_id)