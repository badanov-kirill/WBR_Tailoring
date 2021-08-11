CREATE PROCEDURE [Ozon].[Articles_Set]
	@detail Ozon.ArticlesType READONLY
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	
	
	DECLARE @detail_tab AS TABLE (id INT, pants_id INT, ean VARCHAR(14), art VARCHAR(75), ozon_id INT, ozon_fbo_id INT, ozon_fbs_id INT, price_with_vat DECIMAL(9, 2))
	
	INSERT INTO @detail_tab
		(
			id,
			pants_id,
			ean,
			art,
			ozon_id,
			ozon_fbo_id,
			ozon_fbs_id,
			price_with_vat
		)
	SELECT	d.id,
			ISNULL(e.pants_id, oa.pants_id) pants_id,
			d.ean,
			d.art,
			d.ozon_id,
			d.ozon_fbo_id,
			d.ozon_fbs_id,
			d.price_with_vat
	FROM	@detail d   
			LEFT JOIN	Manufactory.EANCode e
				ON	e.ean = d.ean   
			OUTER APPLY (
			      	SELECT	TOP(1) puc.pants_id
			      	FROM	Logistics.PackingBoxDetail pbd   
			      			INNER JOIN	Manufactory.ProductUnicCode puc
			      				ON	puc.product_unic_code = pbd.product_unic_code
			      	WHERE	pbd.barcode = d.ean
			      ) oa
	
	SELECT	@error_text = CASE 
	      	                   WHEN ISNULL(d.ean, '') = '' OR LEN(d.ean) < 13 THEN 'Есть строка с не валидным ean ' + ISNULL(d.ean, 'null') +
	      	                        ' в строке номер ' + CAST(d.id AS VARCHAR(10))
	      	                   WHEN ISNULL(d.art, '') = '' OR LEN(d.art) < 6 THEN 'Есть строка с не валидным артикулом ' + ISNULL(d.art, 'null') +
	      	                        ' в строке номер ' + CAST(d.id AS VARCHAR(10))
	      	                   WHEN ISNULL(d.ozon_id, 0) = 0 THEN 'Есть строка с не валидным ozon_id ' + CAST(d.ozon_id AS VARCHAR(10)) +
	      	                        ' в строке номер ' + CAST(d.id AS VARCHAR(10))
	      	                   WHEN ISNULL(d.ozon_fbo_id, 0) = 0 THEN 'Есть строка с не валидным ozon_fbo_id ' + CAST(d.ozon_fbo_id AS VARCHAR(10)) +
	      	                        ' в строке номер ' + CAST(d.id AS VARCHAR(10))
	      	                   --WHEN ISNULL(d.ozon_fbs_id, 0) = 0 THEN 'Есть строка с не валидным ozon_fbs_id ' + CAST(d.ozon_fbs_id AS VARCHAR(10)) +
	      	                   --     ' в строке номер ' + CAST(d.id AS VARCHAR(10))
	      	                   WHEN ISNULL(d.price_with_vat, 0) = 0 THEN 'Есть строка с не валидной цоной ' + CAST(d.price_with_vat AS VARCHAR(10)) +
	      	                        ' в строке номер ' + CAST(d.id AS VARCHAR(10))
	      	                   WHEN d.pants_id IS NULL AND d.ean IS NOT NULL THEN 'Есть строка с чужим ean ' + d.ean +
	      	                        ', в строке номер ' + CAST(d.id AS VARCHAR(10))
	      	                   ELSE NULL
	      	              END
	FROM	@detail_tab d
	WHERE	ISNULL(d.ean, '') = ''
			OR	LEN(d.ean) < 13
			OR	ISNULL(d.art, '') = ''
			OR	LEN(d.art) < 6
			OR	ISNULL(d.ozon_id, 0) = 0
			OR	ISNULL(d.ozon_fbo_id, 0) = 0
			OR	ISNULL(d.ozon_fbs_id, 0) = 0
			OR	ISNULL(d.price_with_vat, 0) = 0
			OR	d.pants_id IS NULL
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	@detail_tab do
	   )
	BEGIN
	    RAISERROR('Нет строк в файле', 16, 1)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION 	
		
		MERGE Ozon.Articles t
		USING @detail_tab s
				ON s.pants_id = t.pants_id
		WHEN MATCHED AND (t.art != s.art OR t.ozon_id != s.ozon_id OR t.ozon_fbo_id != s.ozon_fbo_id OR t.ozon_fbs_id != s.ozon_fbs_id OR t.price_with_vat != s.price_with_vat) THEN 
		     UPDATE	
		     SET 	art                = s.art,
		     		ozon_id            = s.ozon_id,
		     		ozon_fbo_id        = s.ozon_fbo_id,
		     		ozon_fbs_id        = s.ozon_fbs_id,
		     		price_with_vat     = s.price_with_vat
		WHEN NOT MATCHED THEN 
		     INSERT
		     	(
		     		pants_id,
		     		art,
		     		ozon_id,
		     		ozon_fbo_id,
		     		ozon_fbs_id,
		     		price_with_vat
		     	)
		     VALUES
		     	(
		     		s.pants_id,
		     		s.art,
		     		s.ozon_id,
		     		s.ozon_fbo_id,
		     		s.ozon_fbs_id,
		     		s.price_with_vat
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
GO	