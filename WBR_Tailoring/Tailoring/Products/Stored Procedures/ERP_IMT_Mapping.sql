CREATE PROCEDURE [Products].[ERP_IMT_Mapping]
	@imt_id INT,
	@sketch_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	DECLARE @sa VARCHAR(36)
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @dt DATETIME2(0) = GETDATE()
	
	SELECT	@error_text = CASE 
	      	                   WHEN eifm.imt_id IS NULL THEN 'ИМТ с кодом ' + CAST(v.imt_id AS VARCHAR(10)) + ' отсутствует в очереди на связывание.'
	      	                   ELSE NULL
	      	              END,
			@sa = eifm.sa
	FROM	(VALUES(@imt_id))v(imt_id)   
			LEFT JOIN	Products.ERP_IMT_ForMapping eifm
				ON	eifm.imt_id = v.imt_id
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN s.sketch_id IS NULL THEN 'Эскиза с номером ' + CAST(v.sketch_id AS VARCHAR(10)) + ' не существует'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@sketch_id))v(sketch_id)   
			LEFT JOIN	Products.Sketch s
				ON	s.sketch_id = v.sketch_id   
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION 
		
		DELETE	
		FROM	Products.ERP_IMT_ForMapping
		WHERE	imt_id = @imt_id
		
		;
		MERGE Products.ERP_IMT_Sketch t
		USING (
		      	SELECT	@imt_id          imt_id,
		      			@sketch_id       sketch_id,
		      			@sa              sa,
		      			@employee_id     employee_id,
		      			@dt              dt
		      ) s
				ON t.imt_id = s.imt_id
		WHEN MATCHED THEN 
		     UPDATE	
		     SET 	t.sketch_id = s.sketch_id,
		     		t.sa = s.sa,
		     		t.employee_id = s.employee_id,
		     		t.dt = s.dt
		WHEN NOT MATCHED THEN 
		     INSERT
		     	(
		     		imt_id,
		     		sketch_id,
		     		sa,
		     		employee_id,
		     		dt
		     	)
		     VALUES
		     	(
		     		s.imt_id,
		     		s.sketch_id,
		     		s.sa,
		     		s.employee_id,
		     		s.dt
		     	);
		
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