CREATE PROCEDURE [Suppliers].[Supplier_Upd]
	@supplier_id INT,
	@supplier_name VARCHAR(100),
	@employee_id INT,
	@is_deleted BIT,
	@contract_xml XML
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @contract_tab TABLE (suppliercontract_code VARCHAR(9) NOT NULL, suppliercontract_name VARCHAR(100) NOT NULL, contract_number VARCHAR(100) NOT NULL, is_default BIT NOT NULL, suppliercontract_erp_id INT NOT NULL, currency_id INT NULL )
	DECLARE @supplier_source_id TINYINT = 1
	
	INSERT INTO @contract_tab
		(
			suppliercontract_code,
			suppliercontract_name,
			contract_number,
			is_default,
			suppliercontract_erp_id,
			currency_id
		)
	SELECT	ml.value('@code', 'varchar(9)') suppliercontract_code,
			ml.value('@name', 'varchar(100)') suppliercontract_name,
			ml.value('@num', 'varchar(100)') contract_number,
			ml.value('@def', 'bit') is_default,
			ml.value('@erpid', 'int') suppliercontract_erp_id,
			ml.value('@currencyid', 'int') currency_id
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
	
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		MERGE Suppliers.Supplier t
		USING (
		      	SELECT	@supplier_id       supplier_id,
		      			@supplier_name     supplier_name,
		      			@employee_id       employee_id,
		      			@dt                dt,
		      			@is_deleted        is_deleted,
		      			@supplier_source_id supplier_source_id
		      ) s
				ON s.supplier_id = t.supplier_id
		WHEN  MATCHED  THEN 
		     UPDATE	
		     SET 	supplier_name     = s.supplier_name,
		     		employee_id       = s.employee_id,
		     		dt                = s.dt,
		     		is_deleted        = s.is_deleted
		WHEN NOT MATCHED  THEN 
		     INSERT
		     	(
		     		supplier_id,
		     		supplier_name,
		     		employee_id,
		     		dt,
		     		is_deleted,
		     		supplier_source_id
		     	)
		     VALUES
		     	(
		     		s.supplier_id,
		     		s.supplier_name,
		     		s.employee_id,
		     		s.dt,
		     		s.is_deleted,
		     		s.supplier_source_id
		     	);
		
		WITH cte_Target AS
			(
				SELECT	sc.suppliercontract_id,
						sc.supplier_id,
						sc.suppliercontract_code,
						sc.suppliercontract_name,
						sc.contract_number,
						sc.is_default, 
						sc.suppliercontract_erp_id,
						sc.currency_id						
				FROM	Suppliers.SupplierContract sc
				WHERE	sc.supplier_id = @supplier_id
			)
		MERGE cte_Target t
		USING @contract_tab s
				ON s.suppliercontract_erp_id = t.suppliercontract_erp_id
		WHEN  MATCHED  THEN 
		     UPDATE	
		     SET 	suppliercontract_name = s.suppliercontract_name,
		     		contract_number     = s.contract_number,
		     		is_default          = s.is_default,
		     		suppliercontract_code = s.suppliercontract_code,
		     		currency_id			= s.currency_id
		WHEN NOT MATCHED BY TARGET THEN 
		     INSERT
		     	(
		     		supplier_id,
		     		suppliercontract_code,
		     		suppliercontract_name,
		     		contract_number,
		     		is_default,
		     		suppliercontract_erp_id,
		     		currency_id
		     	)
		     VALUES
		     	(
		     		@supplier_id,
		     		s.suppliercontract_code,
		     		s.suppliercontract_name,
		     		s.contract_number,
		     		s.is_default,
		     		s.suppliercontract_erp_id,
		     		s.currency_id
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