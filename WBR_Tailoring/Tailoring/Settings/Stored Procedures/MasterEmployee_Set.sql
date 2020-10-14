CREATE PROCEDURE [Settings].[MasterEmployee_Set]
	@employee_id INT,
	@employee_xml XML
AS
	SET NOCOUNT ON
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @employee_tab TABLE (employee_id INT)
	
	INSERT INTO @employee_tab
		(
			employee_id
		)
	SELECT	ml.value('@id', 'int')
	FROM	@employee_xml.nodes('root/det')x(ml)
	
	BEGIN TRY
		WITH cte_target AS (
			SELECT	me.master_employee_id,
					me.employee_id,
					me.dt
			FROM	Settings.MasterEmployee me
			WHERE	me.master_employee_id = @employee_id
		)
		
		MERGE cte_target t
		USING @employee_tab s
				ON t.employee_id = s.employee_id
		WHEN NOT MATCHED BY TARGET THEN 
		     INSERT
		     	(
		     		master_employee_id,
		     		employee_id,
		     		dt
		     	)
		     VALUES
		     	(
		     		@employee_id,
		     		s.employee_id,
		     		@dt
		     	)
		WHEN NOT MATCHED BY SOURCE THEN 
		     DELETE	;
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