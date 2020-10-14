CREATE PROCEDURE [Reports].[TimeTrackingOtherDay_GetByEmployee]
	@employee_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	TOP(25) ttod.ttod_id,
			CAST(ttod.ttod_start_dt AS DATETIME) ttod_start_dt,
			CAST(ttod.ttod_finish_dt AS DATETIME) ttod_finish_dt,
			ttodt.ttod_type_name,
			tts.tt_state_name,
			ttod.ttod_type_id,
			ttod.tt_state_id
	FROM	Reports.TimeTrackingOtherDay ttod   
			INNER JOIN	Reports.TimeTrackingOtherDayType ttodt
				ON	ttodt.ttod_type_id = ttod.ttod_type_id   
			INNER JOIN	Reports.TimeTrackingState tts
				ON	tts.tt_state_id = ttod.tt_state_id
	WHERE	ttod.ttod_employee_id = @employee_id
	ORDER BY
		ttod.ttod_start_dt DESC
	