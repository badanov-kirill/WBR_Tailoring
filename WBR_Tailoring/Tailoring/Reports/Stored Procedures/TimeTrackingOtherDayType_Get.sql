CREATE PROCEDURE [Reports].[TimeTrackingOtherDayType_Get]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	ttodt.ttod_type_id,
			ttodt.ttod_type_name
	FROM	Reports.TimeTrackingOtherDayType ttodt
	ORDER BY
		ttodt.ttod_type_id