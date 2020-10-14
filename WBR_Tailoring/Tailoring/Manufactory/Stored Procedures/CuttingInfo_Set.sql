CREATE PROCEDURE [Manufactory].[CuttingInfo_Set]
	@cdd_xml XML,
	@employee_id INT,
	@sketch_xml XML
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @cdd_tab TABLE (pan_id INT, cutting_degree_difficulty DECIMAL(4, 2))
	DECLARE @sketch_tab TABLE(sketch_id INT, pt_id TINYINT)
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @dt dbo.SECONDSTIME = GETDATE()	
	
	INSERT INTO @cdd_tab
	  (
	    pan_id,
	    cutting_degree_difficulty
	  )
	SELECT	v.pan_id,
			MAX(v.cutting_degree_difficulty) cutting_degree_difficulty
	FROM	(SELECT	ml.value('@id', 'int') pan_id,
	    	 		ml.value('@cdd', 'decimal(4,2)') cutting_degree_difficulty
	    	 FROM	@cdd_xml.nodes('root/nm')x(ml))v
	GROUP BY
		v.pan_id
	
	INSERT INTO @sketch_tab
	  (
	    sketch_id,
	    pt_id
	  )
	SELECT	ml.value('@id', 'int')         sketch_id,
			ml.value('@pt', 'tinyint')     pt_id
	FROM	@sketch_xml.nodes('root/sketch')x(ml)
	
	SELECT	@error_text = 'Цветомоделей с кодами : '
	      	+
	      	STUFF(
	      		(
	      			SELECT	', ' + CAST(ct.pan_id AS VARCHAR(10))
	      			FROM	@cdd_tab ct   
	      					LEFT JOIN	Products.ProdArticleNomenclature n
	      						ON	n.pan_id = ct.pan_id
	      			WHERE	n.pan_id IS NULL
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
	
	SELECT	@error_text = CASE 
	      	                   WHEN s.sketch_id IS NULL THEN 'Эскиза с кодом ' + CAST(d.sketch_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN pt.pt_id IS NULL THEN 'Типа продукта с кодом ' + CAST(d.pt_id AS VARCHAR(3)) + ' не существует'
	      	                   ELSE NULL
	      	              END
	FROM	@sketch_tab d   
			LEFT JOIN	Products.Sketch s
				ON	s.sketch_id = d.sketch_id   
			LEFT JOIN	Products.ProductType pt
				ON	pt.pt_id = d.pt_id
	WHERE	s.sketch_id IS NULL
			OR	pt.pt_id IS NULL
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		UPDATE	pan
		SET 	cutting_degree_difficulty = t.cutting_degree_difficulty
		    	OUTPUT	INSERTED.pan_id,
		    			INSERTED.pa_id,
		    			INSERTED.sa,
		    			INSERTED.is_deleted,
		    			INSERTED.employee_id,
		    			INSERTED.dt,
		    			INSERTED.nm_id,
		    			INSERTED.whprice,
		    			INSERTED.price_ru,
		    			INSERTED.cutting_degree_difficulty
		    	INTO	History.ProdArticleNomenclature (
		    			pan_id,
		    			pa_id,
		    			sa,
		    			is_deleted,
		    			employee_id,
		    			dt,
		    			nm_id,
		    			whprice,
		    			price_ru,
		    			cutting_degree_difficulty
		    		)
		FROM	Products.ProdArticleNomenclature pan
				INNER JOIN	@cdd_tab t
					ON	t.pan_id = pan.pan_id
		
		UPDATE	s
		SET 	pt_id = t.pt_id
		FROM	Products.Sketch s
				INNER JOIN	@sketch_tab t
					ON	t.sketch_id = s.sketch_id 
		
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