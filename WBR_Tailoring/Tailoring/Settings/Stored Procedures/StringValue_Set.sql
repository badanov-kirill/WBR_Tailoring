CREATE PROCEDURE [Settings].[StringValue_Set]
	@code CHAR(3),
	@svalue VARCHAR(200),
	@employee_id INT
AS
	SET NOCOUNT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	
	BEGIN TRY
		MERGE Settings.StringValue t
		USING (
		      	SELECT	@code       code,
		      			@svalue     svalue
		      )s
				ON t.code = s.code
		WHEN MATCHED THEN 
		     UPDATE	
		     SET 	t.svalue = s.svalue,
		     		t.dt = @dt,
		     		t.employee_id = @employee_id
		WHEN NOT MATCHED THEN 
		     INSERT
		     	(
		     		code,
		     		svalue,
		     		dt,
		     		employee_id
		     	)
		     VALUES
		     	(
		     		s.code,
		     		s.svalue,
		     		@dt,
		     		@employee_id
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
		
		
		RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess) WITH LOG;
	END CATCH 
				