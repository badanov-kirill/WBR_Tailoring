CREATE PROCEDURE [Settings].[DepartmentSetting_Set]
	@department_id INT,
	@department_name VARCHAR(100),
	@office_id INT,
	@employee_id INT,
	@parrent_department_id INT = NULL
AS
	SET NOCOUNT ON
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Settings.OfficeSetting os
	   	WHERE	os.office_id = @office_id
	   )
	BEGIN
	    RAISERROR('Офиса с кодом %d не существует', 16, 1, @office_id)
	    RETURN
	END
	
	IF @parrent_department_id IS NOT NULL
	   AND NOT EXISTS(
	       	SELECT	1
	       	FROM	Settings.DepartmentSetting ds
	       	WHERE	ds.department_id = @parrent_department_id
	       )
	BEGIN
	    RAISERROR('Отдела с кодом %d не существует', 16, 1, @parrent_department_id)
	    RETURN
	END
	
	BEGIN TRY
		;
		MERGE Settings.DepartmentSetting t
		USING (
		      	SELECT	@department_id       department_id,
		      			@office_id           office_id,
		      			@department_name     department_name,
		      			@employee_id         employee_id,
		      			@dt                  dt,
		      			@parrent_department_id parrent_department_id
		      ) s
				ON t.department_id = s.department_id
		WHEN MATCHED THEN 
		     UPDATE	
		     SET 	t.office_id = s.office_id,
		     		t.department_name = s.department_name,
		     		t.dt = s.dt,
		     		t.employee_id = s.employee_id,
		     		t.parrent_department_id = s.parrent_department_id
		WHEN NOT MATCHED THEN 
		     INSERT
		     	(
		     		department_id,
		     		office_id,
		     		department_name,
		     		dt,
		     		employee_id,
		     		parrent_department_id
		     	)
		     VALUES
		     	(
		     		s.department_id,
		     		s.office_id,
		     		s.department_name,
		     		s.dt,
		     		s.employee_id,
		     		s.parrent_department_id
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