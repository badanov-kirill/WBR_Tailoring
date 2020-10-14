CREATE PROCEDURE [Warehouse].[SHKSuspectUnit_Upd]
	@shks_id INT,
	@descript VARCHAR(900),
	@okei_id INT,
	@shksu_id INT = NULL,
	@qty DECIMAL(9, 3),
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()         
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Warehouse.SHKSuspect s
	   	WHERE	s.shks_id = @shks_id
	   )
	BEGIN
	    RAISERROR('ШК обезличенного товара не найден %d', 16, 1, @shks_id)
	    RETURN
	END
	
	IF @shksu_id IS NOT NULL
	   AND NOT EXISTS (
	       	SELECT	1
	       	FROM	Warehouse.SHKSpaceUnit su
	       	WHERE	su.shksu_id = @shksu_id
	       )
	BEGIN
	    RAISERROR('ШК грузового места не найден %d', 16, 1, @shksu_id)
	    RETURN
	END
	
	BEGIN TRY
		UPDATE	Warehouse.SHKSuspectUnit
		SET 	descript        = @descript,
				shksu_id        = @shksu_id,
				okei_id         = @okei_id,
				qty             = @qty,
				dt              = @dt,
				employee_id     = @employee_id
		WHERE	shks_id         = @shks_id
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