CREATE PROCEDURE [Reports].[TimeTracking_GetByEmployee]
	@employee_id INT,
	@start_dt DATE = NULL,
	@finish_dt DATE = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	IF @start_dt IS NULL
	BEGIN
		SET @start_dt = DATEADD(DAY, -45, GETDATE())
	END
	
	SELECT	tt.tt_id,
			CAST(tt.tt_dt AS DATETIME)     tt_dt,
			tt.tt_hour,
			tts.tt_state_name,
			tt.tt_state_id
	FROM	Reports.TimeTracking tt   
			INNER JOIN	Reports.TimeTrackingState tts
				ON	tts.tt_state_id = tt.tt_state_id
	WHERE	tt.tt_employee_id = @employee_id
			AND	tt.tt_dt >= @start_dt
			AND (@finish_dt IS NULL OR tt.tt_dt <= @finish_dt)
	ORDER BY
		tt.tt_dt                           DESC