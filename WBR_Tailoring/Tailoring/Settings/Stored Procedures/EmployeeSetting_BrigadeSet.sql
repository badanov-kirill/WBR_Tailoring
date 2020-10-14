CREATE PROCEDURE [Settings].[EmployeeSetting_BrigadeSet]
	@brigade_id INT,
	@data_xml XML
AS
	SET NOCOUNT ON
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @data_tab TABLE (employee_id INT)
	
	IF @brigade_id IS NOT NULL
	   AND NOT EXISTS (
	       	SELECT	1
	       	FROM	Settings.Brigade b
	       	WHERE	b.brigade_id = @brigade_id
	       )
	BEGIN
	    RAISERROR('Бригады с кодом %d не существует.', 16, 1, @brigade_id)
	    RETURN
	END
	
	INSERT INTO @data_tab
		(
			employee_id
		)
	SELECT	ml.value('@id[1]', 'int')
	FROM	@data_xml.nodes('root/det')x(ml)
	
	SET @error_text = 'Сотудников с кодами: ' + (
	    	SELECT	ISNULL(CAST(dt.employee_id AS VARCHAR(10)), 'null') + '; '
	    	FROM	@data_tab dt   
	    			LEFT JOIN	Settings.EmployeeSetting es
	    				ON	es.employee_id = dt.employee_id
	    	WHERE	es.employee_id IS NULL
	    	FOR XML	PATH('')
	    ) + ' не существует'
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		UPDATE	es
		SET 	brigade_id = @brigade_id
		FROM	Settings.EmployeeSetting es
				INNER JOIN	@data_tab dt
					ON	dt.employee_id = es.employee_id
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