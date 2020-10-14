CREATE PROCEDURE [Settings].[OfficeSetting_Get]
	@office_id INT = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	ts.office_id,
			ts.office_name,
			ts.buffer_zone_place_id
	FROM	Settings.OfficeSetting ts
	WHERE	@office_id IS NULL
			OR	ts.office_id = @office_id