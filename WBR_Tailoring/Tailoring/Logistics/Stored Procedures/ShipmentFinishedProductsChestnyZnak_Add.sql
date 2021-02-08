CREATE PROCEDURE [Logistics].[ShipmentFinishedProductsChestnyZnak_Add]
	@sfp_id INT,
	@oczdi_id INT,
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
	      	                    WHEN oczdi.oczdi_id IS NULL THEN 'ШК с идентификатором ' + CAST(v.oczdi_id AS VARCHAR(20)) + 'не существует.'
	      	                    WHEN sfpcz.oczdi_id IS NOT NULL AND sfpcz.sfp_id = @sfp_id THEN 'Этот шк уже в этом документе'
	      	                    WHEN sfpcz.oczdi_id IS NOT NULL AND sfpcz.sfp_id != @sfp_id THEN 'Этот шк уже в другом документе № ' + CAST(sfpcz.sfp_id AS VARCHAR(10))
	      	                    ELSE NULL
	      	               END
	FROM	(VALUES(@oczdi_id))v(oczdi_id)   
			LEFT JOIN Manufactory.OrderChestnyZnakDetailItem oczdi
			ON oczdi.oczdi_id = v.oczdi_id
			LEFT JOIN Logistics.ShipmentFinishedProductsChestnyZnak sfpcz
			ON v.oczdi_id = oczdi.oczdi_id
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END			
	
	BEGIN TRY
		BEGIN TRANSACTION		
			
		INSERT INTO Logistics.ShipmentFinishedProductsChestnyZnak
		(
			sfp_id,
			oczdi_id,
			dt,
			employee_id
		)
		VALUES
			(
				@sfp_id,
				@oczdi_id,
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