CREATE PROCEDURE [Logistics].[ShipmentFinishedProductsDetail_Add]
	@sfp_id INT,
	@transfer_box_id BIGINT,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	
	SELECT	@error_text = CASE 
	      	                   WHEN s.sfp_id IS NULL THEN 'Отгрузки с номером ' + CAST(v.sfp_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN s.complite_dt IS NOT NULL THEN 'Отгрузка № ' + CAST(s.sfp_id AS VARCHAR(10)) + ' уже отправлена'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@sfp_id))v(sfp_id)   
			LEFT JOIN	Logistics.ShipmentFinishedProducts s
				ON	s.sfp_id = v.sfp_id   
	
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                    WHEN tb.transfer_box_id IS NULL THEN 'Коробки с номером ' + CAST(v.transfer_box_id AS VARCHAR(20)) + 'не существует.'
	      	                    WHEN sfpd.transfer_box_id IS NOT NULL AND sfpd.sfp_id = @sfp_id THEN 'Коробки с номером ' + CAST(v.transfer_box_id AS VARCHAR(20)) 
	      	                         + ' уже в этом документе'
	      	                    WHEN sfpd.transfer_box_id IS NOT NULL AND sfpd.sfp_id != @sfp_id THEN 'Коробки с номером ' + CAST(v.transfer_box_id AS VARCHAR(20)) 
	      	                         + ' уже в документе № ' + CAST(sfpd.sfp_id AS VARCHAR(10))
	      	                    ELSE NULL
	      	               END
	FROM	(VALUES(@transfer_box_id))v(transfer_box_id)   
			LEFT JOIN	Logistics.TransferBox tb
				ON	tb.transfer_box_id = v.transfer_box_id   
			LEFT JOIN	Logistics.ShipmentFinishedProductsDetail sfpd
				ON	sfpd.transfer_box_id = tb.transfer_box_id
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END			
	
	BEGIN TRY
		BEGIN TRANSACTION		
		
		UPDATE	Logistics.TransferBox
		SET 	close_dt = @dt,
				close_employee_id = @employee_id
		WHERE	close_dt IS NULL
		AND transfer_box_id = @transfer_box_id
			
		INSERT INTO Logistics.ShipmentFinishedProductsDetail
			(
				sfp_id,
				transfer_box_id,
				dt,
				employee_id
			)
		VALUES
			(
				@sfp_id,
				@transfer_box_id,
				@dt,
				@employee_id
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
		
		RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess) WITH LOG;
	END CATCH 	