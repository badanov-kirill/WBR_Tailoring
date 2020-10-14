CREATE PROCEDURE [Manufactory].[TaskChinaSample_Add]
	@sketch_id INT,
	@employee_id INT,
	@comment VARCHAR(250) = NULL
AS
	SET NOCOUNT ON
	
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	
	SELECT	@error_text = CASE 
	      	                   WHEN s.sketch_id IS NULL THEN 'Эскиза с номером ' + CAST(v.sketch_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN s.tech_design = 0 THEN 'Необходимо сначала прикрепить технический эскиз'
	      	                   WHEN s.is_china_sample = 0 THEN 'Это не Китайский образец.'
	      	                   WHEN s.specification_dt IS NULL THEN 'Не прикреплен файл'
	      	                   WHEN s.is_deleted = 1 THEN 'Эскиз удален, нльзя добавлять макет/образц'
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
	
	IF EXISTS(
	   	SELECT	1
	   	FROM	Manufactory.TaskChinaSample tcs
	   	WHERE	tcs.sketch_id = @sketch_id
	   			AND	tcs.close_dt IS NULL
	   )
	BEGIN
	    RAISERROR('На этот эскиз уже есть не закрытое задание', 16, 1)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		INSERT INTO Manufactory.TaskChinaSample
			(
				sketch_id,
				create_dt,
				create_employee_id,
				close_dt,
				close_employee_id,
				comment
			)
		VALUES
			(
				@sketch_id,
				@dt,
				@employee_id,
				NULL,
				NULL,
				@comment
			)
		
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