CREATE PROCEDURE [Settings].[TransferSetting_Get]
AS
	SET NOCOUNT ON 
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	ts.ts_id,
			ts.setting_name,
			ts.office_id,
			os.office_name,
			os.buffer_zone_place_id,
			sp.place_name
	FROM	Settings.TransferSetting ts   
			INNER JOIN	Settings.OfficeSetting os
				ON	os.office_id = ts.office_id   
			INNER JOIN	Warehouse.StoragePlace sp
				ON	sp.place_id = os.buffer_zone_place_id
	WHERE	ts.is_deleted = 0
