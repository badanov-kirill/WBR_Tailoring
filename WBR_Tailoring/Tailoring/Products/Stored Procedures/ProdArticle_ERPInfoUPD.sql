CREATE PROCEDURE [Products].[ProdArticle_ERPInfoUPD]
	@pa_id INT,
	@nm_xml XML,
	@imt_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @nmsa_tab TABLE(sa VARCHAR(36), nm_id INT, PRIMARY KEY CLUSTERED(sa))
	DECLARE @error_text VARCHAR(MAX)
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Products.ProdArticle pa
	   	WHERE	pa.pa_id = @pa_id
	   )
	BEGIN
	    RAISERROR('Артикула с кодом %d не существует', 16, 1, @pa_id);
	    RETURN
	END
	
	INSERT INTO @nmsa_tab
	  (
	    sa,
	    nm_id
	  )
	SELECT	ml.value('@sa', 'varchar(36)') sa,
			ml.value('@nm', 'int') nm_id
	FROM	@nm_xml.nodes('root/item')x(ml)
	
	SELECT	@error_text = CASE 
	      	                   WHEN pan.sa IS NULL THEN 'Артикула цвета ' + nt.sa + ' не существует'
	      	                   ELSE NULL
	      	              END
	FROM	@nmsa_tab nt   
			LEFT JOIN	Products.ProdArticleNomenclature pan
				ON	pan.sa = nt.sa
				AND	pan.pa_id = @pa_id
	WHERE	pan.sa IS NULL
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION 
		
		UPDATE	Products.ProdArticle
		SET 	imt_id = @imt_id
		WHERE	pa_id = @pa_id
		
		UPDATE	pan
		SET 	nm_id = nt.nm_id
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
				INNER JOIN	@nmsa_tab nt
					ON	nt.sa = pan.sa
		WHERE	pan.pa_id = @pa_id
		
		INSERT INTO Products.ProdArticleNomenclatureNeedPrice
		  (
		    pan_id,
		    dt,
		    employee_id
		  )
		SELECT	pan.pan_id,
				@dt,
				@employee_id
		FROM	Products.ProdArticleNomenclature pan
		WHERE	pan.pa_id = @pa_id
				AND	pan.nm_id IS NOT NULL
				AND	NOT EXISTS (
				   		SELECT	1
				   		FROM	Products.ProdArticleNomenclatureNeedPrice panp
				   		WHERE	panp.pan_id = pan.pan_id
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