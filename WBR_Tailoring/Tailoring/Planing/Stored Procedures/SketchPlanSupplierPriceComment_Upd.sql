CREATE PROCEDURE [Planing].[SketchPlanSupplierPriceComment_Upd]
	@spsp_id INT,
	@employee_id INT,
	@comment VARCHAR(200),
	@order_num VARCHAR(10) = NULL
AS
	SET NOCOUNT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	
	SELECT	@error_text = CASE 
	      	                   WHEN spsp.spsp_id IS NULL THEN 'Строчки цены с кодом ' + CAST(v.spsp_id AS VARCHAR(10)) + ' не существует.'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@spsp_id))v(spsp_id)   
			LEFT JOIN	Planing.SketchPlanSupplierPrice spsp
				ON	spsp.spsp_id = v.spsp_id
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		UPDATE	Planing.SketchPlanSupplierPrice
		SET 	comment         = @comment,
				employee_id     = @employee_id,
				dt              = @dt,
				order_num       = ISNULL(@order_num, order_num)				
				OUTPUT	INSERTED.spsp_id,
						INSERTED.sp_id,
						INSERTED.supplier_id,
						INSERTED.price_ru,
						INSERTED.dt,
						INSERTED.employee_id,
						INSERTED.comment,
						INSERTED.order_num
				INTO	History.SketchPlanSupplierPrice (
						spsp_id,
						sp_id,
						supplier_id,
						price_ru,
						dt,
						employee_id,
						comment,
						order_num
					)
		WHERE	spsp_id = @spsp_id
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
	