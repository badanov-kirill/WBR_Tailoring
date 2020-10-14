CREATE PROCEDURE [Manufactory].[PrintLabel]
	@count SMALLINT,
	@employee_id INT,
	@office_id INT,
	@pants_id INT,
	@cutting_id INT = NULL
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt dbo.SECONDSTIME = GETDATE()	
	DECLARE @print_operation SMALLINT = 7
	DECLARE @ut TABLE (product_unic_code INT)
	
	DECLARE @pt_id TINYINT
	
	SELECT	@pt_id = s.pt_id
	FROM	Products.ProdArticleNomenclatureTechSize pants   
			INNER JOIN	Products.ProdArticleNomenclature pan
				ON	pan.pan_id = pants.pan_id   
			INNER JOIN	Products.ProdArticle pa
				ON	pa.pa_id = pan.pa_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = pa.sketch_id
	WHERE	pants.pants_id = @pants_id
	
	IF @pt_id IS NULL
	BEGIN
	    RAISERROR('Не удалось определить тип продукта , при планировании необходимо указать тип продукта заново.', 16, 1)
	    RETURN
	END
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Settings.OfficeSetting AS bo
	   	WHERE	bo.office_id = @office_id
	   )
	BEGIN
	    RAISERROR('Филиала с кодом %d не существует.', 16, 1, @office_id)
	    RETURN
	END
	
	IF @cutting_id IS NOT NULL
	   AND NOT EXISTS(
	       	SELECT	1
	       	FROM	Manufactory.Cutting c
	       	WHERE	c.cutting_id = @cutting_id
	       )
	BEGIN
	    RAISERROR('Строчки плана с кодом %d не существует.', 16, 1, @cutting_id)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		INSERT INTO @ut
		  (
		    product_unic_code
		  )
		SELECT	NEXT VALUE
		FOR Manufactory.ProductSeq  AS unic_code
		    FROM dbo.Number           n
		    WHERE n.id > 0
		    AND n.id <= @count		
		
		INSERT INTO Manufactory.ProductUnicCode
		  (
		    product_unic_code,
		    operation_id,
		    dt,
		    pt_id,
		    pants_id,
		    cutting_id
		  )
		SELECT	ut.product_unic_code,
				@print_operation,
				@dt,
				@pt_id,
				@pants_id,
				@cutting_id
		FROM	@ut ut	
		
		INSERT INTO Manufactory.ProductOperations
		  (
		    product_unic_code,
		    operation_id,
		    office_id,
		    employee_id,
		    dt,
		    is_uniq
		  )OUTPUT	INSERTED.product_unic_code
		
		SELECT	ut.product_unic_code,
				@print_operation,
				@office_id,
				@employee_id,
				@dt,
				1
		FROM	@ut ut 
		
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