CREATE PROCEDURE [Reports].[TimeTracking_GroupUpd_v1]
	@data_tab dbo.List READONLY,
	@tt_state_id INT,
	@start_dt DATE,
	@finish_dt DATE,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @out_tab TABLE (tt_id INT, tt_state_id TINYINT)
	
	DECLARE @other_tab TABLE (ttod_id INT)
	
	INSERT INTO @other_tab
		(
			ttod_id
		)
	SELECT	ttod.ttod_id
	FROM	Reports.TimeTrackingOtherDay ttod   
			INNER JOIN	@data_tab dt
				ON	ttod.ttod_employee_id = dt.id
	WHERE	ttod.tt_state_id = 1
			AND	(
			   		(ttod.ttod_start_dt < @start_dt AND ttod.ttod_finish_dt > @start_dt)
			   		OR (ttod.ttod_start_dt < @finish_dt AND ttod.ttod_finish_dt > @finish_dt)
			   		OR (ttod.ttod_start_dt BETWEEN @start_dt AND @finish_dt)
			   		OR (ttod.ttod_finish_dt BETWEEN @start_dt AND @finish_dt)
			   	)
	
	BEGIN TRY
		BEGIN TRANSACTION 
		
		UPDATE	tt
		SET 	tt_state_id = @tt_state_id,
				dt = @dt,
				employee_id = @employee_id
				OUTPUT	INSERTED.tt_id
				INTO	@out_tab (
						tt_id
					)
		FROM	Reports.TimeTracking tt
		WHERE	tt.tt_dt >= @start_dt
				AND	tt.tt_dt <= @finish_dt
				AND	tt.tt_state_id = 1
				AND	EXISTS(
				   		SELECT	1
				   		FROM	@data_tab dt
				   		WHERE	tt.tt_employee_id = dt.id
				   	)
		
		UPDATE	ttod
		SET 	tt_state_id = @tt_state_id,
				dt = @dt,
				employee_id = @employee_id
		FROM	Reports.TimeTrackingOtherDay ttod
				INNER JOIN	@other_tab ot
					ON	ot.ttod_id = ttod.ttod_id
		
		INSERT INTO History.TimeTracking
			(
				tt_id,
				dt,
				employee_id,
				tt_state_id
			)
		SELECT	ot.tt_id,
				@dt,
				@employee_id,
				@tt_state_id
		FROM	@out_tab ot
		
		INSERT INTO History.TimeTrackingOtherDay
			(
				ttod_id,
				dt,
				employee_id,
				tt_state_id
			)
		SELECT	ot.ttod_id,
				@dt,
				@employee_id,
				@tt_state_id
		FROM	@other_tab ot
		
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
		    ROLLBACK TRANSACTION
		
		DECLARE @ErrNum INT = ERROR_NUMBER();
		DECLARE @estate INT = ERROR_STATE();
		DECLARE @esev INT = ERROR_SEVERITY();
		DECLARE @Line INT = ERROR_LINE();
		DECLARE @Mess VARCHAR(MAX) = CHAR(10) + ISNULL('Процедура: ' + ERROR_PROCEDURE(), '') 
		        + CHAR(10) + ERROR_MESSAGE();
		
		RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess) 
		WITH LOG;
	END CATCH 