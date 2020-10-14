CREATE PROCEDURE [Warehouse].[MaterialInProductionDetailNom_Add]
	@mip_id INT,
	@pan_id INT,
	@employee_id INT,
	@rv_bigint BIGINT,
	@proportion TINYINT = 100
AS
	SET NOCOUNT ON
	
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @rv ROWVERSION = CAST(@rv_bigint AS ROWVERSION)
	DECLARE @with_log BIT = 1
	DECLARE @nm_id INT
	DECLARE @sa VARCHAR(72)
	DECLARE @art_name VARCHAR(100)
	DECLARE @tab_output TABLE (rv_bigint VARCHAR(19))
	DECLARE @mipdn_id INT
	DECLARE @workshop_id INT
	
	SELECT	@error_text = CASE 
	      	                   WHEN mip.mip_id IS NULL THEN 'Заказа в производство с номером ' + CAST(v.mip_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN mip.complite_dt IS NOT NULL THEN 'Заказ в производство закрыт, добавлять позиции нельзя'
	      	                   WHEN mip.workshop_id IS NULL THEN 'Сначала укажите цех.'
	      	                   WHEN mip.rv != @rv THEN 'Документ уже кто-то поменял, перечитайте данные и попробуйте снова'
	      	                   ELSE NULL
	      	              END,
			@workshop_id = mip.workshop_id
	FROM	(VALUES(@mip_id))v(mip_id)   
			LEFT JOIN	Warehouse.MaterialInProduction mip
				ON	mip.mip_id = v.mip_id
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN pan.pan_id IS NULL THEN 'Модели с внутренним кодом номенклатуры ' + CAST(v.pan_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN pan.nm_id IS NULL THEN 'Артикул не записан на сайт, добавлять нельзя'
	      	                   WHEN mipdn.mip_id IS NOT NULL THEN 'Артикул уже в документе'
	      	                   WHEN oa.mip_id IS NOT NULL THEN 'В этот цех уже запущена эта модель в документе ' + CAST(oa.mip_id AS VARCHAR(10))
	      	                   ELSE NULL
	      	              END,
			@sa           = pa.sa + pan.sa,
			@nm_id        = pan.nm_id,
			@art_name     = an.art_name
	FROM	(VALUES(@pan_id))v(pan_id)   
			LEFT JOIN	Products.ProdArticleNomenclature pan   
			INNER JOIN	Products.ProdArticle pa
				ON	pa.pa_id = pan.pa_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = pa.sketch_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id
				ON	pan.pan_id = v.pan_id   
			LEFT JOIN	Warehouse.MaterialInProductionDetailNom mipdn
				ON	mipdn.mip_id = @mip_id
				AND	mipdn.pan_id = v.pan_id   
			OUTER APPLY (
			      	SELECT	TOP(1) mip2.mip_id
			      	FROM	Warehouse.MaterialInProduction mip2   
			      			INNER JOIN	Warehouse.MaterialInProductionDetailNom mipdn2
			      				ON	mipdn2.mip_id = mip2.mip_id
			      	WHERE	mipdn2.pan_id = v.pan_id
			      			AND	mip2.workshop_id = @workshop_id
			      			AND	mip2.complite_dt IS NULL
			      ) oa
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		UPDATE	Warehouse.MaterialInProduction
		SET 	dt = @dt,
				employee_id = @employee_id
				OUTPUT	CAST(CAST(INSERTED.rv AS BIGINT) AS VARCHAR(19))
				INTO	@tab_output (
						rv_bigint
					)
		WHERE	mip_id = @mip_id
				AND	rv = @rv
		
		IF @@ROWCOUNT = 0
		BEGIN
		    SET @with_log = 0
		    RAISERROR('Документ уже кто-то поменял, перечитайте данные и попробуйте снова', 16, 1);
		    RETURN
		END 
		
		INSERT INTO Warehouse.MaterialInProductionDetailNom
		  (
		    mip_id,
		    pan_id,
		    proportion,
		    dt,
		    employee_id
		  )
		VALUES
		  (
		    @mip_id,
		    @pan_id,
		    @proportion,
		    @dt,
		    @employee_id
		  ) 
		
		SET @mipdn_id = SCOPE_IDENTITY()
		
		COMMIT TRANSACTION
		
		SELECT	@mipdn_id       mipdn_id,
				@pan_id         pan_id,
				@nm_id          nm_id,
				@sa             sa,
				@art_name       art_name,
				@proportion     proportion,
				t.rv_bigint
		FROM	@tab_output     t
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
		
		IF @with_log = 1
		BEGIN
		    RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess) WITH LOG;
		END
		ELSE
		BEGIN
		    RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess)
		END
	END CATCH 