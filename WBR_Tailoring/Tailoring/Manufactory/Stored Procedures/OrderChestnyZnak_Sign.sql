CREATE PROCEDURE [Manufactory].[OrderChestnyZnak_Sign]
	@ocz_id INT,
	@employee_id INT,
	@body_text VARCHAR(MAX),
	@signature_text VARCHAR(MAX)
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @fabricator_id INT
	
	SELECT	@error_text = CASE 
	      	                   WHEN ocz.ocz_id IS NULL THEN 'Заказа с номером ' + CAST(v.ocz_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN ocz.is_deleted = 1 THEN 'Заказ уже удален'
	      	                   WHEN ocz.sign_dt IS NOT NULL THEN 'Заказ уже подписан.'
	      	                   ELSE NULL
	      	              END,
	      	@fabricator_id = ocz.fabricator_id              
	FROM	(VALUES(@ocz_id))v(ocz_id)   
			LEFT JOIN	Manufactory.OrderChestnyZnak ocz
				ON	ocz.ocz_id = v.ocz_id
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION 
		
		MERGE Synchro.OrderChestnyZnakSign t
		USING (
		      	SELECT	@ocz_id ocz_id
		      ) s(ocz_id)
				ON s.ocz_id = t.ocz_id
		WHEN MATCHED THEN 
		     UPDATE	
		     SET 	body_text          = @body_text,
		     		signature_text     = @signature_text,
		     		create_dt          = @dt,
		     		employee_id        = @employee_id,
		     		count_send         = 0,
		     		fabricator_id	 = @fabricator_id
		WHEN NOT MATCHED THEN 
		     INSERT
		     	(
		     		ocz_id,
		     		body_text,
		     		signature_text,
		     		create_dt,
		     		employee_id,
		     		count_send,
		     		fabricator_id
		     	)
		     VALUES
		     	(
		     		@ocz_id,
		     		@body_text,
		     		@signature_text,
		     		@dt,
		     		@employee_id,
		     		0,
		     		@fabricator_id
		     	);
		
		UPDATE	Manufactory.OrderChestnyZnak
		SET 	dt = @dt,
				employee_id = @employee_id,
				sign_dt = @dt
		WHERE	ocz_id = @ocz_id
		
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
	
