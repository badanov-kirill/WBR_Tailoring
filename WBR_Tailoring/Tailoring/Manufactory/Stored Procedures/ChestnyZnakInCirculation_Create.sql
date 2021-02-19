CREATE PROCEDURE [Manufactory].[ChestnyZnakInCirculation_Create]
	@employee_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED
	SET XACT_ABORT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @tab_out TABLE (czic_id INT)
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Manufactory.OrderChestnyZnakDetailItem oczdi   
	   			LEFT JOIN	Manufactory.ChestnyZnakInCirculationDetail czicd
	   				ON	czicd.oczdi_id = oczdi.oczdi_id
	   			INNER JOIN Manufactory.ProductUnicCode_ChestnyZnakItem pucczi
					ON pucczi.oczdi_id = oczdi.oczdi_id
				INNER JOIN Manufactory.ProductUnicCode puc
					ON puc.product_unic_code = pucczi.product_unic_code
	   	WHERE	czicd.oczdi_id IS NULL
	   			AND	oczdi.oczd_id IS NOT NULL
	   )
	BEGIN
	    RAISERROR('Нет позиций для ввода в оборот', 16, 1)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION 
		
		INSERT INTO Manufactory.ChestnyZnakInCirculation
			(
				dt,
				employee_id
			)OUTPUT	INSERTED.czic_id
			 INTO	@tab_out (
			 		czic_id
			 	)
		VALUES
			(
				@dt,
				@employee_id
			)
		
		INSERT INTO Manufactory.ChestnyZnakInCirculationDetail
			(
				czic_id,
				oczdi_id
			)
		SELECT TOP(100)	to1.czic_id,
				oczdi.oczdi_id
		FROM	Manufactory.OrderChestnyZnakDetailItem oczdi   
				CROSS JOIN	@tab_out to1
				INNER JOIN Manufactory.ProductUnicCode_ChestnyZnakItem pucczi
					ON pucczi.oczdi_id = oczdi.oczdi_id
		WHERE	oczdi.oczd_id IS NOT NULL
				AND	NOT EXISTS (
				   		SELECT	1
				   		FROM	Manufactory.ChestnyZnakInCirculationDetail czicd
				   		WHERE	czicd.oczdi_id = oczdi.oczdi_id
				   	)
		
		COMMIT TRANSACTION
		
		SELECT	to1.czic_id
		FROM	@tab_out to1
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