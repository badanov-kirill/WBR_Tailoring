﻿CREATE PROCEDURE [Warehouse].[SHKRawMaterial_Print]
	@count SMALLINT,
	@employee_id INT
AS
	SET NOCOUNT ON
	DECLARE @dt dbo.SECONDSTIME = GETDATE()	
	
	IF @count > 600
	BEGIN
	    RAISERROR('Нельзя печатать больше 600 наклеек единовременно', 16, 1)
	    RETURN
	END
	
	BEGIN TRY
		INSERT INTO Warehouse.SHKRawMaterial
		  (
		    dt,
		    employee_id
		  )OUTPUT	INSERTED.shkrm_id
		
		SELECT	@dt,
				@employee_id
		FROM	dbo.Number n
		WHERE	n.id > 0
				AND	n.id <= @count
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