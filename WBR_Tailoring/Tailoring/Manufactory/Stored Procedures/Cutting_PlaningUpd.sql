CREATE PROCEDURE [Manufactory].[Cutting_PlaningUpd]
	@employee_id INT,
	@data_xml XML
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @tab_data_xml TABLE (cutting_id INT, employee_xml XML, is_planing BIT)
	DECLARE @employee_tab TABLE(cutting_id INT, employee_id INT)
	DECLARE @error_text VARCHAR(MAX)
	
	INSERT INTO @tab_data_xml
	  (
	    cutting_id,
	    employee_xml,
	    is_planing
	  )
	SELECT	ml.value('@id', 'int')     cutting_id,
			ml.query('employes')       employee_xml,
			ml.value('@ip', 'bit')     is_planing
	FROM	@data_xml.nodes('root/detail')x(ml)   
	
	
	INSERT INTO @employee_tab
	  (
	    cutting_id,
	    employee_id
	  )
	SELECT	d.cutting_id,
			ml.value('@id', 'int') employee_id
	FROM	@tab_data_xml d   
			CROSS APPLY d.employee_xml.nodes('employes/empl')x(ml)
	
	
	SELECT	@error_text = 'Плана с кодом: '
	      	+
	      	STUFF(
	      		(
	      			SELECT	', ' + CAST(d.cutting_id AS VARCHAR(10))
	      			FROM	@tab_data_xml d   
	      					LEFT JOIN	Manufactory.Cutting c
	      						ON	c.cutting_id = d.cutting_id
	      			WHERE	c.cutting_id IS NULL
	      			FOR XML	PATH('')
	      		),
	      		1,
	      		2,
	      		''
	      	)
	      	+
	      	' не существует'
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION 
		
		
		UPDATE	c
		SET 	employee_id             = @employee_id,
				dt                      = @dt,
				planing_employee_id     = @employee_id,
				planing_dt              = @dt
		FROM	Manufactory.Cutting c
				INNER JOIN	@tab_data_xml d
					ON	d.cutting_id = c.cutting_id
		
		;
		WITH cte_Target AS
		(
			SELECT	ce.cutting_id,
					ce.employee_id
			FROM	Manufactory.CuttingEmployee ce
			WHERE	EXISTS(
			     		SELECT	1
			     		FROM	@tab_data_xml et
			     		WHERE	ce.cutting_id = et.cutting_id
			     	)
		)
		MERGE cte_Target t
		USING (
		      	SELECT	et.cutting_id,
		      			et.employee_id
		      	FROM	@employee_tab et
		      ) s
				ON t.cutting_id = s.cutting_id
				AND t.employee_id = s.employee_id
		WHEN NOT MATCHED BY TARGET THEN 
		     INSERT
		     	(
		     		cutting_id,
		     		employee_id
		     	)
		     VALUES
		     	(
		     		s.cutting_id,
		     		s.employee_id
		     	)
		WHEN NOT MATCHED BY SOURCE THEN 
		     DELETE	;
		
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