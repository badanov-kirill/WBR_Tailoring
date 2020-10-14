CREATE PROCEDURE [Suppliers].[RawMaterialStockReserv_Del]
	@spcvc_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	
	IF EXISTS (
	   	SELECT	1
	   	FROM	Suppliers.RawMaterialStockReserv rmsr   
	   			INNER JOIN	Suppliers.RawMaterialOrderDetailFromReserv rmodfr
	   				ON	rmodfr.rmsr_id = rmsr.rmsr_id
	   	WHERE	rmsr.spcvc_id = @spcvc_id
	   			AND	rmodfr.rmods_id != 2
	   )
	BEGIN
	    RAISERROR('По этой позиции уже есть заказ', 16, 1, @spcvc_id)
	    RETURN
	END
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Planing.SketchPlanColorVariantCompleting spcvc
	   	WHERE	spcvc.spcvc_id = @spcvc_id
	   )
	BEGIN
	    RAISERROR('Строчки плана с кодом %d не существует.', 16, 1, @spcvc_id)
	    RETURN
	END
	
	BEGIN TRY
		DELETE	r
		FROM	Suppliers.RawMaterialStockReserv r
		WHERE	r.spcvc_id = @spcvc_id
				AND	NOT EXISTS (
				   		SELECT	1
				   		FROM	Suppliers.RawMaterialOrderDetailFromReserv rmodfr
				   		WHERE	rmodfr.rmsr_id = r.rmsr_id
				   	)
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