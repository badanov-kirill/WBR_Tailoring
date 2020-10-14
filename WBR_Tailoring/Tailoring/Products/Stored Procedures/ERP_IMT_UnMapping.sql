CREATE PROCEDURE [Products].[ERP_IMT_UnMapping]
	@nm_id INT,
	@sketch_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	DECLARE @imt_id INT
	DECLARE @sa VARCHAR(36)
	DECLARE @brand_id INT
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @dt DATETIME2(0) = GETDATE()
	
	SELECT	@error_text = CASE 
	      	                   WHEN s.sketch_id IS NULL THEN 'Эскиза с номером ' + CAST(v.sketch_id AS VARCHAR(10)) + ' не существует'
	      	                   ELSE NULL
	      	              END,
			@brand_id = s.brand_id
	FROM	(VALUES(@sketch_id))v(sketch_id)   
			LEFT JOIN	Products.Sketch s
				ON	s.sketch_id = v.sketch_id   
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	SELECT	@imt_id = ens.imt_id,
			@sa = eis.sa
	FROM	Products.ERP_NM_Sketch ens   
			INNER JOIN	Products.ERP_IMT_Sketch eis
				ON	eis.imt_id = ens.imt_id
	WHERE	ens.nm_id = @nm_id
			AND	eis.sketch_id = @sketch_id
	
	IF @imt_id IS NULL
	BEGIN
	    RAISERROR('Номенклатура с кодом %d не связана с эскизом', 16, 1, @nm_id)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		INSERT INTO Products.ERP_IMT_ForMapping
			(
				imt_id,
				descr,
				sa,
				brand_id,
				collection_id,
				season_id,
				kind_id,
				subject_id,
				style_id,
				dt
			)
		VALUES
			(
				@imt_id,
				'',
				@sa,
				@brand_id,
				NULL,
				NULL,
				NULL,
				NULL,
				NULL,
				@dt
			)
		
		DELETE	Products.ERP_IMT_Sketch
		WHERE	imt_id = @imt_id
				AND	sketch_id = @sketch_id		
		
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