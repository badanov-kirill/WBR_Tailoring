CREATE PROCEDURE [Settings].[EmployeeEquipment_Set]
	@employee_id INT,
	@data_xml XML
AS
	SET NOCOUNT ON
	DECLARE @data_tab TABLE (equipment_id INT)
	
	INSERT INTO @data_tab
		(
			equipment_id
		)
	SELECT	ml.value('@id[1]', 'int')
	FROM	@data_xml.nodes('root/det')x(ml)
	
	BEGIN TRY
		WITH cte_target AS (
			SELECT	ee.employee_id,
					ee.equipment_id
			FROM	Settings.EmployeeEquipment ee
			WHERE	ee.employee_id = @employee_id
		)
		
		MERGE cte_target t
		USING @data_tab s
				ON t.equipment_id = s.equipment_id
		WHEN NOT MATCHED BY TARGET THEN 
		     INSERT
		     	(
		     		employee_id,
		     		equipment_id
		     	)
		     VALUES
		     	(
		     		@employee_id,
		     		s.equipment_id
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