CREATE PROCEDURE [Planing].[SketchPlanColorVariantCompleting_SetSupplier]
	@spcvc_id INT,
	@employee_id INT,
	@supplier_id INT
AS
	SET NOCOUNT ON
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	
	SELECT	@error_text = CASE 
	      	                   WHEN spcvc.spcvc_id IS NULL THEN 'Кода потребноcти материала цветоварианта ' + CAST(v.spcvc_id AS VARCHAR(10)) +
	      	                        ' не существует.'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@spcvc_id))v(spcvc_id)   
			LEFT JOIN	Planing.SketchPlanColorVariantCompleting spcvc
				ON	spcvc.spcvc_id = v.spcvc_id 
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	IF @supplier_id IS NOT NULL
	   AND NOT EXISTS (
	       	SELECT	1
	       	FROM	Suppliers.Supplier s
	       	WHERE	s.supplier_id = @supplier_id
	       )
	BEGIN
	    RAISERROR('Поставщика с кодом %d не существует', 16, 1, @supplier_id)
	    RETURN
	END
	
	BEGIN TRY
		UPDATE	Planing.SketchPlanColorVariantCompleting
		SET 	dt              = @dt,
				employee_id     = @employee_id,
				supplier_id     = @supplier_id
		WHERE	spcvc_id        = @spcvc_id
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
	