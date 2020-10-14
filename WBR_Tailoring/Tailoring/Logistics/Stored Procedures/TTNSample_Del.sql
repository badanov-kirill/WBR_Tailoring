CREATE PROCEDURE [Logistics].[TTNSample_Del]
	@sample_id INT,
	@employee_id INT,
	@ttn_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	
	SELECT	@error_text = CASE 
	      	                   WHEN t.ttn_id IS NULL THEN 'ТТН с номером ' + CAST(v.ttn_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN t.complite_dt IS NOT NULL THEN 'ТТН с номером ' + CAST(v.ttn_id AS VARCHAR(10)) + ' уже закрытка.'
	      	                   WHEN s.close_dt IS NOT NULL THEN 'Отгрузка № ' + CAST(s.shipping_id AS VARCHAR(10)) + ' уже отправлена'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@ttn_id))v(ttn_id)   
			LEFT JOIN	Logistics.TTN t
				ON	t.ttn_id = v.ttn_id   
			LEFT JOIN	Logistics.Shipping s
				ON	s.shipping_id = t.shipping_id	
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Logistics.TTNSample t
	   	WHERE	t.ttn_id = @ttn_id
	   			AND	t.sample_id = @sample_id
	   )
	BEGIN
	    RAISERROR('Этого образеца нет в документе', 16, 1)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION	
		
		DELETE	
		FROM	Logistics.TTNSample
		WHERE	ttn_id = @ttn_id
				AND	sample_id = @sample_id
		
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