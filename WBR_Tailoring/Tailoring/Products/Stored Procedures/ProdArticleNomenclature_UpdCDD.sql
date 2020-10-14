CREATE PROCEDURE [Products].[ProdArticleNomenclature_UpdCDD]
	@cdd_xml XML,
	@employee_id INT
AS
	SET NOCOUNT ON
	
	DECLARE @cdd_tab TABLE (pan_id INT, cutting_degree_difficulty DECIMAL(4, 2))
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @dt DATETIME2(0) = GETDATE()	
	
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
	
	BEGIN TRY
		UPDATE	pan
		SET 	cutting_degree_difficulty = t.cutting_degree_difficulty,
				pan.employee_id = @employee_id,
				pan.dt = @dt
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