CREATE PROCEDURE [Suppliers].[SupplierVSA_Upd]
	@buh_cod VARCHAR(9),
	@buh_uid_str VARCHAR(36),
	@supplier_name VARCHAR(100),
	@employee_id INT,
	@is_deleted BIT,
	@contract_xml XML
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @buh_uid UNIQUEIDENTIFIER = CAST(@buh_uid_str AS UNIQUEIDENTIFIER)
	DECLARE @out_tab TABLE (supplier_id INT)
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @supplier_source_id TINYINT = 2
	DECLARE @supplier_id INT
	
	DECLARE @contract_tab TABLE (
	        	suppliercontract_code VARCHAR(9) NOT NULL,
	        	suppliercontract_name VARCHAR(100) NOT NULL,
	        	contract_number VARCHAR(100) NOT NULL,
	        	is_default BIT NOT NULL,
	        	buh_uid UNIQUEIDENTIFIER NOT NULL,
	        	currency_id INT NULL,
	        	currency_code VARCHAR(3) NULL
	        )
	
	INSERT INTO @contract_tab
		(
			suppliercontract_code,
			suppliercontract_name,
			contract_number,
			is_default,
			buh_uid,
			currency_code
		)
	SELECT	ml.value('@code', 'varchar(9)') suppliercontract_code,
			ml.value('@name', 'varchar(100)') suppliercontract_name,
			ml.value('@num', 'varchar(100)') contract_number,
			ml.value('@def', 'bit') is_default,
			CAST(ml.value('@uid', 'varchar(36)') AS UNIQUEIDENTIFIER) buh_uid,
			ml.value('@currency', 'varchar(3)') currency_code
	FROM	@contract_xml.nodes('contrs/contr')x(ml)
	
	IF EXISTS (
	   	SELECT	1
	   	FROM	@contract_tab ct
	   	WHERE	ct.is_default = 1
	   	HAVING
	   		COUNT(*) > 1
	   )
	BEGIN
	    RAISERROR('Не может быть несколько основных договоров', 16, 1)
	    RETURN
	END
	
	UPDATE	d
	SET 	currency_id = c.currency_id
	FROM	@contract_tab d
			INNER JOIN	RefBook.Currency c
				ON	c.buh_code = d.currency_code
	
	SELECT	@error_text = 'У договора ' + c.suppliercontract_name + ' не верный код валюты ' + ISNULL(c.currency_code, 'null')
	FROM	@contract_tab c
	WHERE	c.currency_id IS NULL
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	SELECT @supplier_id = s.supplier_id
	FROM Suppliers.Supplier s
	WHERE s.buh_uid = @buh_uid
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		IF @supplier_id IS NULL
		BEGIN
			SET @supplier_id = NEXT VALUE FOR Suppliers.SupplierSeq
		END
		
		MERGE Suppliers.Supplier t
		USING (
		      	SELECT	@supplier_id supplier_id,
		      	@supplier_name     supplier_name,
		      			@employee_id       employee_id,
		      			@dt                dt,
		      			@is_deleted        is_deleted,
		      			@buh_cod           buh_cod,
		      			@buh_uid           buh_uid,
		      			@supplier_source_id supplier_source_id
		      ) s
				ON s.supplier_id = t.supplier_id
		WHEN MATCHED THEN 
		     UPDATE	
		     SET 	supplier_name     = s.supplier_name,
		     		employee_id       = s.employee_id,
		     		dt                = s.dt,
		     		is_deleted        = s.is_deleted,
		     		buh_cod           = s.buh_cod,
		     		supplier_source_id = s.supplier_source_id
		WHEN NOT MATCHED THEN 
		     INSERT
		     	(
		     		supplier_id,
		     		supplier_name,
		     		employee_id,
		     		dt,
		     		is_deleted,
		     		buh_cod,
		     		buh_uid,
		     		supplier_source_id
		     	)
		     VALUES
		     	(
		     		s.supplier_id,
		     		s.supplier_name,
		     		s.employee_id,
		     		s.dt,
		     		s.is_deleted,
		     		s.buh_cod,
		     		s.buh_uid,
		     		s.supplier_source_id
		     	) 
		     ;
		
		WITH cte_Target AS
		(
			SELECT	sc.suppliercontract_id,
					sc.supplier_id,
					sc.suppliercontract_code,
					sc.suppliercontract_name,
					sc.contract_number,
					sc.is_default,
					sc.suppliercontract_erp_id,
					sc.currency_id,
					sc.buh_uid
			FROM	Suppliers.SupplierContract sc
			WHERE	sc.supplier_id = @supplier_id
		)
		MERGE cte_Target t
		USING (
		      	SELECT	ct.suppliercontract_code,
		      			ct.suppliercontract_name,
		      			ct.contract_number,
		      			ct.is_default,
		      			ct.buh_uid,
		      			ct.currency_id,
		      			@supplier_id supplier_id
		      	FROM	@contract_tab ct   
		      ) s
				ON s.buh_uid = t.buh_uid
		WHEN MATCHED THEN 
		     UPDATE	
		     SET 	suppliercontract_name = s.suppliercontract_name,
		     		contract_number     = s.contract_number,
		     		is_default          = s.is_default,
		     		suppliercontract_code = s.suppliercontract_code,
		     		currency_id         = s.currency_id
		WHEN NOT MATCHED BY TARGET THEN 
		     INSERT
		     	(
		     		supplier_id,
		     		suppliercontract_code,
		     		suppliercontract_name,
		     		contract_number,
		     		is_default,
		     		currency_id,
		     		buh_uid
		     	)
		     VALUES
		     	(
		     		s.supplier_id,
		     		s.suppliercontract_code,
		     		s.suppliercontract_name,
		     		s.contract_number,
		     		s.is_default,
		     		s.currency_id,
		     		s.buh_uid
		     	);
		
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