CREATE PROCEDURE [Settings].[EmployeeTransferSetting_Del]
	@employee_id INT,
	@delete_employee_id INT
AS
	SET NOCOUNT ON
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	
	
	BEGIN TRY
		DELETE	
		FROM	Settings.EmployeeTransferSetting
		    	OUTPUT	DELETED.employee_id,
		    			NULL ts_id,
		    			@delete_employee_id,
		    			@dt,
		    			1
		    	INTO	History.EmployeeTransferSetting (
		    			employee_id,
		    			ts_id,
		    			creator_employee_id,
		    			dt,
		    			is_deleted
		    		)
		WHERE	employee_id = @employee_id
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