CREATE PROCEDURE [Reports].[TimeTrackingOtherDay_Add]
	@ttod_employee_id INT,
	@start_dt DATE,
	@finish_dt DATE,
	@ttot_type_id TINYINT,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @tab_out TABLE (ttod_id INT)
	DECLARE @tt_state_id TINYINT = 1
	
	IF @finish_dt < @start_dt
	BEGIN
	    RAISERROR('Некорректный диапазон дат', 16, 1)
	    RETURN
	END
	
	IF DATEDIFF(DAY, @start_dt, @dt) > 45
	BEGIN
	    RAISERROR('Нельзя вносить данные больше 45 дней назад', 16, 1)
	    RETURN
	END
	
	IF DATEDIFF(DAY, @dt, @finish_dt) > 45
	BEGIN
	    RAISERROR('Нельзя вносить данные больше 45 дней вперед', 16, 1)
	    RETURN
	END
	
	IF DATEDIFF(DAY, @finish_dt, @finish_dt) > 28
	BEGIN
	    RAISERROR('Нельзя вносить период больше 28 дней. Если требуется больше, внесите несколькими периодами', 16, 1)
	    RETURN
	END
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Settings.EmployeeSetting es
	   	WHERE	es.employee_id = @ttod_employee_id
	   )
	BEGIN
	    RAISERROR('Сотрудника с кодом %d не существует', 16, 1, @ttod_employee_id)
	    RETURN
	END
	
	
	IF EXISTS(
	   	SELECT	1
	   	FROM	Reports.TimeTrackingOtherDay ttod
	   	WHERE	ttod.ttod_employee_id = @ttod_employee_id
	   			AND	ttod.tt_state_id IN (1, 2, 3)
	   			AND	(ttod.ttod_start_dt BETWEEN @start_dt AND @finish_dt OR ttod.ttod_finish_dt BETWEEN @start_dt AND @finish_dt)
	   )
	BEGIN
	    RAISERROR('На этот период уже внесены нерабочие дни. Сначала удалите их', 16, 1)
	    RETURN
	END	
	
	BEGIN TRY
		BEGIN TRANSACTION 
		
		INSERT INTO Reports.TimeTrackingOtherDay
			(
				ttod_employee_id,
				ttod_start_dt,
				ttod_finish_dt,
				ttod_type_id,
				tt_state_id,
				dt,
				employee_id
			)OUTPUT	INSERTED.ttod_id
			 INTO	@tab_out (
			 		ttod_id
			 	)
		VALUES
			(
				@ttod_employee_id,
				@start_dt,
				@finish_dt,
				@ttot_type_id,
				@tt_state_id,
				@dt,
				@employee_id
			)
		
		
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
		FROM	@tab_out ot
		
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
