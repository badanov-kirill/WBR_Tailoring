CREATE PROCEDURE [Suppliers].[RawMaterialRefund_Set]
	@rmr_id INT,
	@suppliercontract_id INT,
	@sending_dt DATE = NULL,
	@comment VARCHAR(200) = NULL,
	@employee_id INT,
	@rv_bigint BIGINT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE(),
	        @supplier_id INT,
	        @create_status INT = 1,
	        @rv ROWVERSION = CAST(@rv_bigint AS ROWVERSION),
	        @error_text VARCHAR(MAX)
	
	DECLARE @refund_output TABLE (
	        	rmr_id INT NOT NULL,
	        	supplier_id INT NOT NULL,
	        	suppliercontract_id INT NOT NULL,
	        	rmrs_id TINYINT NOT NULL,
	        	sending_dt DATE NULL,
	        	is_deleted BIT NOT NULL,
	        	dt DATETIME2(0) NOT NULL,
	        	employee_id INT NOT NULL,
	        	comment VARCHAR(200) NULL,
	        	rv_bigint BIGINT NOT NULL
	        ) 
	
	SELECT	@supplier_id = sc.supplier_id
	FROM	Suppliers.SupplierContract sc
	WHERE	sc.suppliercontract_id = @suppliercontract_id
	
	IF @suppliercontract_id IS NULL
	BEGIN
	    RAISERROR('Договора поставщика с ИД %d не существует в базе производства', 16, 1, @suppliercontract_id)
	    RETURN
	END        
	
	IF @rmr_id IS NOT NULL
	BEGIN
	    SELECT	@error_text = CASE 
	          	                   WHEN rmr.rmr_id IS NULL THEN 'Возврата поставщику № ' + CAST(v.rmr_id AS VARCHAR(10)) + ' не существует'
	          	                   WHEN rmr.is_deleted = 1 THEN 'Возврат поставщику № ' + CAST(v.rmr_id AS VARCHAR(10)) + ' помечен на удаление'
	          	                   WHEN rmr.rv != @rv THEN 'Документ уже кто-то поменял. Перечитайте данные и попробуйте записать снова.'
	          	              END
	    FROM	(VALUES(@rmr_id))v(rmr_id)   
	    		LEFT JOIN	Suppliers.RawMaterialRefund rmr
	    			ON	rmr.rmr_id = v.rmr_id    			    
	    
	    IF @error_text IS NOT NULL
	    BEGIN
	        RAISERROR('%s', 16, 1, @error_text)
	        RETURN
	    END
	END
	
	IF @rmr_id IS NULL
	   AND EXISTS (
	       	SELECT	1
	       	FROM	Suppliers.RawMaterialRefund rmr
	       	WHERE	rmr.supplier_id = @supplier_id
	       			AND	rmr.suppliercontract_id = @suppliercontract_id
	       			AND	rmr.sending_dt = @sending_dt
	       			AND	rmr.is_deleted = 0
	       )
	BEGIN
	    DECLARE @dtt VARCHAR(30) = CONVERT(VARCHAR(30), @sending_dt, 120)
	    RAISERROR('Уже существует возврат по поставщику ИД %d и договору ИД %d на дату отгрузки: %s', 16, 1, @supplier_id, @suppliercontract_id, @dtt)
	    RETURN
	END	
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		MERGE Suppliers.RawMaterialRefund t
		USING (
		      	SELECT	@rmr_id rmr_id
		      ) s
				ON t.rmr_id = s.rmr_id
		WHEN  MATCHED AND t.rv = @rv THEN 
		     UPDATE	
		     SET 	t.dt = @dt,
		     		t.employee_id = @employee_id,
		     		t.supplier_id = @supplier_id,
		     		t.suppliercontract_id = @suppliercontract_id,
		     		t.sending_dt = @sending_dt,
		     		t.comment = @comment
		WHEN NOT MATCHED  THEN 
		     INSERT
		     	(
		     		supplier_id,
		     		suppliercontract_id,
		     		rmrs_id,
		     		sending_dt,
		     		is_deleted,
		     		create_dt,
		     		create_employee_id,
		     		dt,
		     		employee_id,
		     		comment
		     	)
		     VALUES
		     	(
		     		@supplier_id,
		     		@suppliercontract_id,
		     		@create_status,
		     		@sending_dt,
		     		0,
		     		@dt,
		     		@employee_id,
		     		@dt,
		     		@employee_id,
		     		@comment
		     	)
		     OUTPUT	INSERTED.rmr_id,
		     		INSERTED.supplier_id,
		     		INSERTED.suppliercontract_id,
		     		INSERTED.rmrs_id,
		     		INSERTED.sending_dt,
		     		INSERTED.is_deleted,
		     		INSERTED.dt,
		     		INSERTED.employee_id,
		     		INSERTED.comment,
		     		CAST(INSERTED.rv AS BIGINT)
		     INTO	@refund_output (
		     		rmr_id,
		     		supplier_id,
		     		suppliercontract_id,
		     		rmrs_id,
		     		sending_dt,
		     		is_deleted,
		     		dt,
		     		employee_id,
		     		comment,
		     		rv_bigint
		     	);
		
		INSERT History.RawMaterialRefund
		  (
		    rmr_id,
		    supplier_id,
		    suppliercontract_id,
		    rmrs_id,
		    sending_dt,
		    is_deleted,
		    dt,
		    employee_id,
		    comment
		  )
		SELECT	rmr_id,
				supplier_id,
				suppliercontract_id,
				rmrs_id,
				sending_dt,
				is_deleted,
				dt,
				employee_id,
				comment
		FROM	@refund_output 
		
		IF @@ROWCOUNT = 0
		BEGIN
		    RAISERROR('Документ уже кто-то успел поменять. Перечитайте данные и попробуйте записать снова.', 16, 1)
		    RETURN
		END 
		
		COMMIT TRANSACTION
		
		SELECT	rmr_id,
				dt,
				rv_bigint
		FROM	@refund_output
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