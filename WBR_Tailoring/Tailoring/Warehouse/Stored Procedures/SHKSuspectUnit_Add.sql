CREATE PROCEDURE [Warehouse].[SHKSuspectUnit_Add]
	@shks_id INT,
	@descript VARCHAR(900),
	@okei_id INT,
	@shksu_id INT,
	@qty DECIMAL(9, 3),
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt             DATETIME2(0) = GETDATE(),
	        @error_text     VARCHAR(MAX)
	
	SELECT	@error_text = CASE 
	      	                   WHEN s.shks_id IS NULL THEN 'Некоректный ШК ' + CAST(v.shks_id AS VARCHAR(10)) + ' для обезличенного товара '
	      	                   WHEN ssu.shksu_id IS NULL THEN 'ШК грузового места ' + CAST(v.shksu_id AS VARCHAR(10)) + ' не найден'
	      	                   WHEN ssu2.shks_id IS NOT NULL THEN 'Данный ШК ' + CAST(v.shks_id AS VARCHAR(10)) + '  уже отмечен для безличенного товара'
	      	              END
	FROM	(VALUES(@shks_id,
			@shksu_id))v(shks_id,
			shksu_id)   
			LEFT JOIN	Warehouse.SHKSuspect s
				ON	s.shks_id = v.shks_id   
			LEFT JOIN	Warehouse.SHKSpaceUnit ssu
				ON	ssu.shksu_id = v.shksu_id   
			LEFT JOIN	Warehouse.SHKSuspectUnit ssu2
				ON	ssu2.shks_id = v.shks_id
	
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('(%s) данные не загружены, проверьте файл.', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		INSERT Warehouse.SHKSuspectUnit
		  (
		    shks_id,
		    descript,
		    shksu_id,
		    okei_id,
		    qty,
		    dt,
		    employee_id
		  )
		VALUES
		  (
		    @shks_id,
		    @descript,
		    @shksu_id,
		    @okei_id,
		    @qty,
		    @dt,
		    @employee_id
		  )
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
GO