CREATE PROCEDURE [Settings].[EmployeeTransferSetting_Set]
	@employee_id INT,
	@ts_id INT,
	@create_employee_id INT
AS
	SET NOCOUNT ON
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Settings.TransferSetting ts
	   	WHERE	ts.ts_id = @ts_id
	   )
	BEGIN
	    RAISERROR('Настройки с кодом %d не существует', 16, 1, @ts_id)
	    RETURN
	END
	
	BEGIN TRY
		;
		MERGE Settings.EmployeeTransferSetting t
		USING (
		      	SELECT	@employee_id     employee_id,
		      			@ts_id           ts_id
		      ) s
				ON t.employee_id = s.employee_id
		WHEN MATCHED THEN 
		     UPDATE	
		     SET 	ts_id = s.ts_id
		WHEN NOT MATCHED THEN 
		     INSERT
		     	(
		     		employee_id,
		     		ts_id
		     	)
		     VALUES
		     	(
		     		s.employee_id,
		     		s.ts_id
		     	)
		     OUTPUT	INSERTED.employee_id,
		     		INSERTED.ts_id,
		     		@create_employee_id,
		     		@dt,
		     		0
		     INTO	History.EmployeeTransferSetting (
		     		employee_id,
		     		ts_id,
		     		creator_employee_id,
		     		dt,
		     		is_deleted
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