CREATE PROCEDURE [Manufactory].[ChestnyZnakInCirculation_Send]
	@czic_id INT,
	@number_cz CHAR(36)
AS
	SET NOCOUNT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	
	DECLARE @error_text VARCHAR(MAX)
	
	SELECT	@error_text = CASE 
	      	                   WHEN czic.czic_id IS NULL THEN 'Документа с кодом ' + CAST(v.czic_id AS VARCHAR(10)) + ' не существует.'
	      	                   --WHEN czic.dt_send IS NOT NULL THEN 'Документ с кодом ' + CAST(v.czic_id AS VARCHAR(10)) + ' уже отправлен в ЧЗ.'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@czic_id))v(czic_id)   
			LEFT JOIN	Manufactory.ChestnyZnakInCirculation czic
				ON	czic.czic_id = v.czic_id   
	
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION 
		
		UPDATE	Manufactory.ChestnyZnakInCirculation
		SET 	dt_send = @dt,
				number_cz = dbo.uid2bin(@number_cz)
		WHERE	czic_id = @czic_id
		
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
	
	
	