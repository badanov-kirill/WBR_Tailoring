CREATE PROCEDURE [Manufactory].[OrderChestnyZnak_Del]
	@ocz_id INT, 
	@employee_id INT
AS
	SET NOCOUNT ON
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	
	SELECT	@error_text = CASE 
	      	                   WHEN ocz.ocz_id IS NULL THEN 'Заказа с номером ' + CAST(v.ocz_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN ocz.is_deleted = 1 THEN 'Заказ уже удален'
	      	                   WHEN ocz.sign_dt IS NOT NULL THEN 'Заказ уже подписан, удалять нельзя.'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@ocz_id))v(ocz_id)   
			LEFT JOIN Manufactory.OrderChestnyZnak ocz ON ocz.ocz_id = v.ocz_id
			
			IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
		BEGIN TRY
		
		UPDATE Manufactory.OrderChestnyZnak
		SET dt = @dt,
		 employee_id = @employee_id,
		 is_deleted = 1
		WHERE ocz_id = @ocz_id
		
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
	
