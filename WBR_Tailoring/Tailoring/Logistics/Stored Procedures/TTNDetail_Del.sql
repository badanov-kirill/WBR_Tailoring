CREATE PROCEDURE [Logistics].[TTNDetail_Del]
	@shkrm_id INT,
	@employee_id INT,
	@ttn_id INT
AS
	SET NOCOUNT ON
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @with_log BIT = 1
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @ps_id INT
	DECLARE @ttnd_id INT
	
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
	
	SELECT	@error_text = CASE 
	      	                   WHEN sm.shkrm_id IS NULL THEN 'Штрихкода ' + CAST(v.shkrm_id AS VARCHAR(10)) + ' не существует.'	      	               
	      	                   WHEN t.shkrm_id IS NULL THEN 'Штрихкод ' + CAST(v.shkrm_id AS VARCHAR(10)) + ' не в документе.'
	      	                   ELSE NULL
	      	              END,
	      	              @ttnd_id = t.ttnd_id
	FROM	(VALUES(@shkrm_id))v(shkrm_id)   
			LEFT JOIN	Warehouse.SHKRawMaterial sm
				ON	sm.shkrm_id = v.shkrm_id    
			LEFT JOIN	Logistics.TTNDetail t
				ON	t.ttn_id = @ttn_id
				AND	t.shkrm_id = v.shkrm_id
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	SELECT	@ps_id = ps.ps_id
	FROM	Planing.PlanShipping ps
	WHERE	ps.ttn_id = @ttn_id
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		UPDATE	psd
		SET 	ttnd_id = NULL
		FROM	Planing.PlanShippingDetail psd
		WHERE	psd.ps_id = @ps_id
				AND	psd.shkrm_id = @shkrm_id
				AND	psd.ttnd_id = @ttnd_id
		
		DELETE	Logistics.TTNDetail
		WHERE ttnd_id = @ttnd_id
		
		INSERT INTO History.TTNDetailDel
		  (
		    ttn_id,
		    shkrm_id,
		    employee_id,
		    dt
		  )
		VALUES
		  (
		    @ttn_id,
		    @shkrm_id,
		    @employee_id,
		    @dt
		  )
		  		
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
		
		IF @with_log = 1
		BEGIN
		    RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess) WITH LOG;
		END
		ELSE
		BEGIN
		    RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess)
		END
	END CATCH 