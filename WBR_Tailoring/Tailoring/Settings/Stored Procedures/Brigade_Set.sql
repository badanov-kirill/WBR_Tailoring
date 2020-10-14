CREATE PROCEDURE [Settings].[Brigade_Set]
	@brigade_id INT = NULL,
	@brigade_name VARCHAR(100),
	@office_id INT,
	@master_employee_id INT,
	@employee_id INT,
	@is_deleted BIT
AS
	SET NOCOUNT ON
	DECLARE @dt DATETIME2(0) = GETDATE()
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Settings.OfficeSetting os
	   	WHERE	os.office_id = @office_id
	   )
	BEGIN
	    RAISERROR('Офиса с кодом %d не существует', 16, 1, @office_id)
	    RETURN
	END
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Settings.EmployeeSetting es
	   	WHERE	es.employee_id = @master_employee_id
	   )
	BEGIN
	    RAISERROR('Сотрудника с кодом %d не существует', 16, 1, @master_employee_id)
	    RETURN
	END
	
	IF EXISTS (
	   	SELECT	1
	   	FROM	Settings.Brigade b
	   	WHERE	b.brigade_name = @brigade_name
	   			AND	(@brigade_id IS NULL OR b.brigade_id != @brigade_id)
	   			AND	b.is_deleted = 0
	   			AND @is_deleted = 0 
	   )
	BEGIN
	    RAISERROR('Наименование не уникально', 16, 1)
	    RETURN
	END
	
	BEGIN TRY
		;
		MERGE Settings.Brigade t
		USING (
		      	SELECT	@brigade_id       brigade_id,
		      			@brigade_name     brigade_name,
		      			@office_id        office_id,
		      			@master_employee_id master_employee_id,
		      			@employee_id      employee_id,
		      			@is_deleted       is_deleted
		      ) s
				ON t.brigade_id = s.brigade_id
		WHEN MATCHED THEN 
		     UPDATE	
		     SET 	brigade_name           = s.brigade_name,
		     		office_id              = s.office_id,
		     		master_employee_id     = s.master_employee_id,
		     		employee_id            = s.employee_id,
		     		dt                     = @dt,
		     		is_deleted             = s.is_deleted
		WHEN NOT MATCHED THEN 
		     INSERT
		     	(
		     		brigade_name,
		     		office_id,
		     		master_employee_id,
		     		employee_id,
		     		dt,
		     		is_deleted
		     	)
		     VALUES
		     	(
		     		s.brigade_name,
		     		s.office_id,
		     		s.master_employee_id,
		     		s.employee_id,
		     		@dt,
		     		s.is_deleted
		     	);
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