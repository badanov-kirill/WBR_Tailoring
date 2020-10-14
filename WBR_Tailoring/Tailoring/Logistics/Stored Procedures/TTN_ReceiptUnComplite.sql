CREATE PROCEDURE [Logistics].[TTN_ReceiptUnComplite]
	@ttn_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @error_text VARCHAR(MAX)
	
	SELECT	@error_text = CASE 
	      	                   WHEN t.ttn_id IS NULL THEN 'ТТН с номером ' + CAST(v.ttn_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN t.complite_dt IS NULL THEN 'ТТН с номером ' + CAST(v.ttn_id AS VARCHAR(10)) + ' не закрытка.'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@ttn_id))v(ttn_id)   
			LEFT JOIN	Logistics.TTN t
				ON	t.ttn_id = v.ttn_id   
	
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		UPDATE	t
		SET 	complite_employee_id = @employee_id,
				complite_dt = NULL
		FROM	Logistics.TTN t
		WHERE	t.ttn_id = @ttn_id
		
		DELETE	da
		FROM	Logistics.TTNDivergenceAct da   
				INNER JOIN	Logistics.TTNDetail td
					ON	td.ttn_id = da.ttn_id
					AND	td.shkrm_id = da.shkrm_id
		WHERE	da.ttn_id = @ttn_id
		
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
		
		
		RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess) WITH LOG;
	END CATCH 