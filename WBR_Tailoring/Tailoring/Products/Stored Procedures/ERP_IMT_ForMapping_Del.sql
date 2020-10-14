CREATE PROCEDURE [Products].[ERP_IMT_ForMapping_Del]
	@imt_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @dt DATETIME2(0) = GETDATE()
	
	SELECT	@error_text = CASE 
	      	                   WHEN eifm.imt_id IS NULL THEN 'ИМТ с кодом ' + CAST(v.imt_id AS VARCHAR(10)) + ' отсутствует в очереди на связывание.'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@imt_id))v(imt_id)   
			LEFT JOIN	Products.ERP_IMT_ForMapping eifm
				ON	eifm.imt_id = v.imt_id
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	
	BEGIN TRY
		INSERT INTO Products.ERP_IMT_Del
			(
				imt_id,
				employee_id,
				dt
			)
		VALUES
			(
				@imt_id,
				@employee_id,
				@dt
			)
		
		DELETE	
		FROM	Products.ERP_IMT_ForMapping
		WHERE	imt_id = @imt_id
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