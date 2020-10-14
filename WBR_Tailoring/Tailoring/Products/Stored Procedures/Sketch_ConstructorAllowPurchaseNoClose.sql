CREATE PROCEDURE [Products].[Sketch_ConstructorAllowPurchaseNoClose]
	@sketch_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @state_constructor_take_job_add TINYINT = 9 --Взят в работу конструктором	
	DECLARE @state_constructor_take_job_add_rework TINYINT = 15 --Взят на доработку конструктором
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	
	SELECT	@error_text = CASE 
	      	                   WHEN s.sketch_id IS NULL THEN 'Эскиза с номером ' + CAST(v.sketch_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN s.ss_id NOT IN (@state_constructor_take_job_add, @state_constructor_take_job_add_rework) THEN 'Текущий статус ' + ss.ss_name 
	      	                        +
	      	                        ' установленый сотрудником с кодом' + CAST(s.employee_id AS VARCHAR(10)) 
	      	                        + ' ' + CONVERT(VARCHAR(20), s.dt, 121) +
	      	                        ' не допускает работы с эмкизом"'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@sketch_id))v(sketch_id)   
			LEFT JOIN	Products.Sketch s
				ON	s.sketch_id = v.sketch_id   
			LEFT JOIN	Products.SketchStatus ss
				ON	ss.ss_id = s.ss_id   
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		UPDATE	s
		SET 	s.allow_purchase_no_close = 1
		FROM	Products.Sketch s
		WHERE	s.sketch_id = @sketch_id
				AND	s.ss_id IN (@state_constructor_take_job_add, @state_constructor_take_job_add_rework)
		
		
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
		
		RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess) WITH LOG;
	END CATCH 