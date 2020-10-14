CREATE PROCEDURE [Settings].[EmployeeSetting_Set]
	@employee_id INT,
	@office_id INT,
	@employee_name VARCHAR(100),
	@change_employee_id INT,
	@department_id INT = NULL,
	@is_work BIT = NULL
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
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
	
	IF @department_id IS NOT NULL
	   AND NOT EXISTS (
	       	SELECT	1
	       	FROM	Settings.DepartmentSetting ds
	       	WHERE	ds.department_id = @department_id
	       )
	BEGIN
	    RAISERROR('Отдела с кодом %d не существует', 16, 1, @department_id)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		;
		MERGE Settings.EmployeeSetting t
		USING (
		      	SELECT	@employee_id       employee_id,
		      			@office_id         office_id,
		      			@employee_name     employee_name,
		      			@change_employee_id change_employee_id,
		      			@dt                dt,
		      			@department_id     department_id,
		      			@is_work           is_work
		      ) s
				ON t.employee_id = s.employee_id
		WHEN MATCHED THEN 
		     UPDATE	
		     SET 	t.office_id = s.office_id,
		     		t.employee_name = s.employee_name,
		     		t.dt = s.dt,
		     		t.change_employee_id = s.change_employee_id,
		     		t.department_id = s.department_id,
		     		t.is_work = s.is_work
		WHEN NOT MATCHED THEN 
		     INSERT
		     	(
		     		employee_id,
		     		office_id,
		     		employee_name,
		     		dt,
		     		change_employee_id,
		     		department_id,
		     		is_work
		     	)
		     VALUES
		     	(
		     		s.employee_id,
		     		s.office_id,
		     		s.employee_name,
		     		s.dt,
		     		s.change_employee_id,
		     		s.department_id,
		     		s.is_work
		     	) 
		     OUTPUT	INSERTED.employee_id,
		     		INSERTED.office_id,
		     		INSERTED.employee_name,
		     		INSERTED.dt,
		     		INSERTED.change_employee_id,
		     		INSERTED.department_id
		     INTO	History.EmployeeSetting (
		     		employee_id,
		     		office_id,
		     		employee_name,
		     		dt,
		     		change_employee_id,
		     		department_id
		     	);
		
		IF @is_work = 1
		BEGIN
		    DELETE	et
		    FROM	Planing.EmployeeTable et
		    WHERE	et.work_employee_id = @employee_id
		    		AND	et.work_dt > @dt
		    
		    DELETE	ee
		    FROM	Settings.EmployeeEquipment ee
		    WHERE	ee.employee_id = @employee_id
		END
		
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