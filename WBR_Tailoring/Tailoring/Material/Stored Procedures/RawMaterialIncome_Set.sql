CREATE PROCEDURE [Material].[RawMaterialIncome_Set]
	@doc_id INT,
	@suppliercontract_id INT,
	@supply_dt DATE,
	@goods_dt DATE = NULL,
	@comment VARCHAR(200) = NULL,
	@payment_comment VARCHAR(200) = NULL,
	@plan_sum DECIMAL(18, 2) = NULL,
	@employee_id INT,
	@rv_bigint BIGINT,
	@company_id INT = NULL	
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE(),
	        @supplier_id INT,
	        @create_status INT = 1,
	        @rv ROWVERSION = CAST(@rv_bigint AS ROWVERSION),
	        @doc_type_id TINYINT = 1,
	        @error_text VARCHAR(MAX),
	        @old_suppliercontract_id INT
	
	DECLARE @income_output TABLE (
	        	doc_id INT NOT NULL,
	        	doc_type_id TINYINT NOT NULL,
	        	rmis_id INT NOT NULL,
	        	dt DATETIME2(0) NOT NULL,
	        	employee_id INT NOT NULL,
	        	supplier_id INT NOT NULL,
	        	suppliercontract_id INT NOT NULL,
	        	supply_dt DATETIME2(0) NOT NULL,
	        	is_deleted BIT NOT NULL,
	        	goods_dt DATETIME2(0) NULL,
	        	comment VARCHAR(200) NULL,
	        	payment_comment VARCHAR(200) NULL,
	        	plan_sum DECIMAL(18, 2) NULL,
	        	scan_load_dt DATETIME2(0) NULL,
	        	rv_bigint BIGINT NOT NULL
	        )  
	
	IF @supply_dt IS NULL
	BEGIN
	    RAISERROR('Не заполнена предполагаемая дата поставки.', 16, 1)
	    RETURN
	END
	
	SELECT	@supplier_id = sc.supplier_id
	FROM	Suppliers.SupplierContract sc
	WHERE	sc.suppliercontract_id = @suppliercontract_id
	
	IF @suppliercontract_id IS NULL
	BEGIN
	    RAISERROR('Договора поставщика с ИД %d не существует в базе производства', 16, 1, @suppliercontract_id)
	    RETURN
	END        
	
	IF @doc_id IS NOT NULL
	BEGIN
	    SELECT	@error_text = CASE 
	          	                   WHEN rmi.doc_id IS NULL THEN 'Поступления материалов № ' + CAST(v.doc_id AS VARCHAR(10)) + ' не существует'
	          	                   WHEN rmi.is_deleted = 1 THEN 'Поступление материалов № ' + CAST(v.doc_id AS VARCHAR(10)) + ' помечен на удаление'
	          	                   WHEN rmi.rv != @rv THEN 'Документ уже кто-то поменял. Перечитайте данные и попробуйте записать снова.'
	          	                   WHEN rmi.rmis_id > 5 AND rmi.suppliercontract_id != @suppliercontract_id THEN 
	          	                        'Нельзя менять договор поставщика после закрытия'
	          	                        --проверка на статус?
	          	                   ELSE NULL
	          	              END,
	          	@old_suppliercontract_id = rmi.suppliercontract_id
	    FROM	(VALUES(@doc_id,
	    		@doc_type_id))v(doc_id,
	    		doc_type_id)   
	    		LEFT JOIN	Material.RawMaterialIncome rmi
	    			ON	rmi.doc_id = v.doc_id
	    			AND	rmi.doc_type_id = v.doc_type_id       
	    
	    IF @error_text IS NOT NULL
	    BEGIN
	        RAISERROR('%s', 16, 1, @error_text)
	        RETURN
	    END
	END
	
	IF @doc_id IS NULL
	   AND EXISTS (
	       	SELECT	1
	       	FROM	Material.RawMaterialIncome rmi
	       	WHERE	rmi.supplier_id = @supplier_id
	       			AND	rmi.suppliercontract_id = @suppliercontract_id
	       			AND	rmi.supply_dt = @supply_dt
	       			AND	rmi.is_deleted = 0
	       )
	BEGIN
	    DECLARE @dtt VARCHAR(30) = CONVERT(VARCHAR(30), @supply_dt, 120)
	    RAISERROR('Уже существует поступление по поставщику ИД %d и договору ИД %d на дату поставки: %s', 16, 1, @supplier_id, @suppliercontract_id, @dtt)
	    RETURN
	END	
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		IF @doc_id IS NULL
		BEGIN
		    SET @doc_id = NEXT VALUE FOR Documents.RawMaterialIncomeSeq
		    
		    INSERT INTO Documents.DocumentID
		      (
		        doc_id,
		        doc_type_id,
		        create_dt,
		        create_employee_id
		      )
		    VALUES
		      (
		        @doc_id,
		        @doc_type_id,
		        @dt,
		        @employee_id
		      )
		END;
		
		MERGE Material.RawMaterialIncome t
		USING (
		      	SELECT	@doc_id              doc_id,
		      			@doc_type_id         doc_type_id,
		      			@create_status       rmis_id,
		      			@dt                  dt,
		      			@employee_id         employee_id,
		      			@supplier_id         supplier_id,
		      			@suppliercontract_id suppliercontract_id,
		      			@payment_comment     payment_comment,
		      			@plan_sum            plan_sum,
		      			@supply_dt           supply_dt,
		      			@goods_dt            goods_dt,
		      			@comment             comment,
		      			@company_id			 company_id
		      ) s
				ON t.doc_id = s.doc_id
				AND t.doc_type_id = s.doc_type_id
		WHEN  MATCHED AND t.rv = @rv THEN 
		     UPDATE	
		     SET 	t.dt = s.dt,
		     		t.employee_id = s.employee_id,
		     		t.supplier_id = s.supplier_id,
		     		t.suppliercontract_id = s.suppliercontract_id,
		     		t.payment_comment = s.payment_comment,
		     		t.plan_sum = s.plan_sum,
		     		t.supply_dt = s.supply_dt,
		     		t.goods_dt = s.goods_dt,
		     		t.comment = s.comment,
		     		t.company_id = s.company_id
		WHEN NOT MATCHED  THEN 
		     INSERT
		     	(
		     		doc_id,
		     		doc_type_id,
		     		rmis_id,
		     		dt,
		     		employee_id,
		     		supplier_id,
		     		payment_comment,
		     		plan_sum,
		     		supply_dt,
		     		is_deleted,
		     		goods_dt,
		     		comment,
		     		suppliercontract_id,
		     		company_id
		     	)
		     VALUES
		     	(
		     		s.doc_id,
		     		s.doc_type_id,
		     		s.rmis_id,
		     		s.dt,
		     		s.employee_id,
		     		s.supplier_id,
		     		s.payment_comment,
		     		s.plan_sum,
		     		s.supply_dt,
		     		0,
		     		s.goods_dt,
		     		s.comment,
		     		s.suppliercontract_id,
		     		s.company_id
		     	)
		     OUTPUT	INSERTED.doc_id,
		     		INSERTED.doc_type_id,
		     		INSERTED.rmis_id,
		     		INSERTED.dt,
		     		INSERTED.employee_id,
		     		INSERTED.supplier_id,
		     		INSERTED.suppliercontract_id,
		     		INSERTED.supply_dt,
		     		INSERTED.is_deleted,
		     		INSERTED.goods_dt,
		     		INSERTED.comment,
		     		INSERTED.payment_comment,
		     		INSERTED.plan_sum,
		     		INSERTED.scan_load_dt,
		     		CAST(INSERTED.rv AS BIGINT)
		     INTO	@income_output (
		     		doc_id,
		     		doc_type_id,
		     		rmis_id,
		     		dt,
		     		employee_id,
		     		supplier_id,
		     		suppliercontract_id,
		     		supply_dt,
		     		is_deleted,
		     		goods_dt,
		     		comment,
		     		payment_comment,
		     		plan_sum,
		     		scan_load_dt,
		     		rv_bigint
		     	);
		
		INSERT History.RawMaterialIncome
		  (
		    doc_id,
		    doc_type_id,
		    rmis_id,
		    dt,
		    employee_id,
		    supplier_id,
		    suppliercontract_id,
		    supply_dt,
		    is_deleted,
		    goods_dt,
		    comment,
		    payment_comment,
		    plan_sum,
		    scan_load_dt
		  )
		SELECT	inc_o.doc_id,
				inc_o.doc_type_id,
				inc_o.rmis_id,
				inc_o.dt,
				inc_o.employee_id,
				inc_o.supplier_id,
				inc_o.suppliercontract_id,
				inc_o.supply_dt,
				inc_o.is_deleted,
				inc_o.goods_dt,
				inc_o.comment,
				inc_o.payment_comment,
				inc_o.plan_sum,
				inc_o.scan_load_dt
		FROM	@income_output inc_o		     	
		
		IF @@ROWCOUNT = 0
		BEGIN
		    RAISERROR('Документ уже кто-то успел поменять. Перечитайте данные и попробуйте записать снова.', 16, 1)
		    RETURN
		END 
		
		IF @old_suppliercontract_id IS NOT NULL AND @old_suppliercontract_id != @suppliercontract_id
		BEGIN
		    UPDATE	Material.RawMaterialIncome
		    SET 	suppliercontract_id = @suppliercontract_id
		    WHERE	doc_id = @doc_id
		    		AND	doc_type_id = @doc_type_id
		    
		    UPDATE	Material.RawMaterialIncomeDetail
		    SET 	suppliercontract_id = @suppliercontract_id
		    WHERE	doc_id = @doc_id
		    		AND	doc_type_id = @doc_type_id
		    
		    UPDATE	Warehouse.SHKRawMaterialActualInfo
		    SET 	suppliercontract_id = @suppliercontract_id
		    WHERE	doc_id = @doc_id
		    		AND	doc_type_id = @doc_type_id
		    
		    UPDATE	Warehouse.SHKRawMaterialInfo
		    SET 	suppliercontract_id     = @suppliercontract_id
		    WHERE	doc_id                  = @doc_id
		    		AND	doc_type_id         = @doc_type_id
		END
		
		COMMIT TRANSACTION
		
		SELECT	inc_o.doc_id,
				inc_o.rv_bigint
		FROM	@income_output inc_o
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