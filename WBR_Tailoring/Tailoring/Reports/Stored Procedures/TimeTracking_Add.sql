CREATE PROCEDURE [Reports].[TimeTracking_Add]
	@tt_employee_id INT,
	@tt_dt DATE,
	@tt_hour DECIMAL(5, 2),
	@employee_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @tab_out TABLE (tt_id INT)
	DECLARE @tt_state_id TINYINT = 1
	
	IF @tt_dt > CAST(@dt AS DATE)
	BEGIN
	    RAISERROR('Нельзя вносить данные будующим числом', 16, 1)
	    RETURN
	END
	
	IF DATEDIFF(DAY, @tt_dt, @dt) > 45
	BEGIN
	    RAISERROR('Нельзя вносить данные больше 45 дней назад', 16, 1)
	    RETURN
	END
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Settings.EmployeeSetting es
	   	WHERE	es.employee_id = @tt_employee_id
	   )
	BEGIN
	    RAISERROR('Сотрудника с кодом %d не существует', 16, 1, @tt_employee_id)
	    RETURN
	END
	
	IF @tt_hour > 15
	BEGIN
	    RAISERROR('Нельзя вносить больше 15 часов', 16, 1)
	    RETURN
	END
	
	IF @tt_hour + (
	   	SELECT	SUM(tt.tt_hour)
	   	FROM	Reports.TimeTracking tt
	   	WHERE	tt.tt_dt = @tt_dt
	   			AND	tt.tt_employee_id = @tt_employee_id
	   			AND	tt.tt_state_id IN (1, 2)
	   ) > 15
	BEGIN
	    RAISERROR('На эту дата уже внесено время. Нельзя вносить больше 15 часов в одни сутки', 16, 1)
	    RETURN
	END	
	
	BEGIN TRY
		BEGIN TRANSACTION 
		
		INSERT INTO Reports.TimeTracking
			(
				tt_dt,
				tt_employee_id,
				tt_hour,
				tt_state_id,
				dt,
				employee_id
			)OUTPUT	INSERTED.tt_id
			 INTO	@tab_out (
			 		tt_id
			 	)
		VALUES
			(
				@tt_dt,
				@tt_employee_id,
				@tt_hour,
				@tt_state_id,
				@dt,
				@employee_id
			)
		
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