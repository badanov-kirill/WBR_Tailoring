CREATE PROCEDURE [Manufactory].[ProductOperation_ReprintCZ]
	@product_unic_code INT,
	@office_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @reprint_cz_operation SMALLINT = 14,
	        @to_packaging_operation SMALLINT = 1,
	        --@reworking_operation SMALLINT = 2,
	        --@cancellation_operation SMALLINT = 3,
	        --@modification_operation SMALLINT = 4,
	        --@special_equipment_operation SMALLINT = 5,
	        @after_packing_of_se SMALLINT = 6,
	        --@print_label_operation SMALLINT = 7,
	        @packaging_operation SMALLINT = 8,
	        --@launch_of_operation SMALLINT = 9,
	        @repair_and_to_packaging_operation SMALLINT = 10
	
	DECLARE @dt_check_defection DATETIME2(0) = DATEADD(hour, -24, @dt)
	DECLARE @proc_id INT	
	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Settings.OfficeSetting AS bo
	   	WHERE	bo.office_id = @office_id
	   )
	BEGIN
	    RAISERROR('Филиала с кодом %d не существует.', 16, 1, @office_id)
	    RETURN
	END
	
	DECLARE @error_text VARCHAR(MAX)
	
	SELECT	@error_text = CASE 
	      	                   WHEN puc.product_unic_code IS NULL THEN 'Такого ШК ' + CAST(v.product_unic_code AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN puc.operation_id NOT IN (@to_packaging_operation, @after_packing_of_se, @packaging_operation, @repair_and_to_packaging_operation) THEN 
	      	                        'Этот товар в статусе ' + o.operation_name + ' . Перепечатывать ЧЗ нельзя'
	      	                   WHEN pucczi.product_unic_code IS NULL THEN 'Зтот товар не связан с кодом маркировки "Честный знак"'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@product_unic_code))v(product_unic_code)   
			LEFT JOIN	Manufactory.ProductUnicCode AS puc   
			INNER JOIN	Manufactory.Operation o
				ON	o.operation_id = puc.operation_id
				ON	puc.product_unic_code = v.product_unic_code   
			LEFT JOIN	Manufactory.ProductUnicCode_ChestnyZnakItem pucczi
				ON	pucczi.product_unic_code = puc.product_unic_code
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	IF EXISTS (
	   	SELECT	1
	   	FROM	Manufactory.ProductOperations po
	   	WHERE	po.product_unic_code = @product_unic_code
	   			AND	po.dt > @dt_check_defection
	   			AND	po.operation_id = @reprint_cz_operation
	   )
	BEGIN
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		INSERT INTO Manufactory.ProductOperations
			(
				product_unic_code,
				operation_id,
				office_id,
				employee_id,
				dt,
				is_uniq
			)
		VALUES
			(
				@product_unic_code,
				@reprint_cz_operation,
				@office_id,
				@employee_id,
				@dt,
				1
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
		
		RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess) 
		WITH LOG;
	END CATCH 