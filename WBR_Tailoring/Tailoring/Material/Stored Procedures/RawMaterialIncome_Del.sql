CREATE PROCEDURE [Material].[RawMaterialIncome_Del]
	@doc_id INT,
	@is_deleted BIT = 1,
	@employee_id INT,
	@rv_bigint BIGINT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt              DATETIME2(0) = GETDATE(),
	        @rv              ROWVERSION = CAST(@rv_bigint AS ROWVERSION),
	        @doc_type_id     TINYINT = 1,
	        @error_text      VARCHAR(MAX)
	
	SELECT	@error_text = CASE 
	      	                   WHEN rmi.doc_id IS NULL THEN 'Поступления материалов № ' + CAST(v.doc_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN rmi.rv != @rv THEN 'Документ уже кто-то поменял. Перечитайте данные и попробуйте записать снова.'
	      	                   WHEN rmi.is_deleted = @is_deleted THEN 'Не верно передан флаг пометки удаления Поступления материалов № ' + CAST(v.doc_id AS VARCHAR(10))
	      	                   WHEN oa_li.invoice_loaded IS NOT NULL THEN 'Нельзя удалять документ после загрузки первичных документов'
	      	                   WHEN rmi_d.rmi_double IS NOT NULL THEN 'Уже существует поступление по поставщику ИД ' + CAST(rmi.supplier_id AS VARCHAR(10)) 
	      	                        + ' и договору ИД ' + CAST(rmi.suppliercontract_id AS VARCHAR(10)) + ' на дату поставки: ' + CONVERT(VARCHAR(30), rmi.supply_dt, 120)
	      	                        --проверка на статус и прочие проверки?
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@doc_id,
			@doc_type_id))v(doc_id,
			doc_type_id)   
			LEFT JOIN	Material.RawMaterialIncome rmi
				ON	rmi.doc_id = v.doc_id
				AND	rmi.doc_type_id = v.doc_type_id   
			OUTER APPLY (
			      	SELECT	1 invoice_loaded
			      	WHERE	EXISTS (
			      	     		SELECT	1
			      	     		FROM	Material.RawMaterialInvoice rm_inv
			      	     		WHERE	rm_inv.doc_id = rmi.doc_id
			      	     				AND	rm_inv.doc_type_id = rmi.doc_type_id
			      	     				AND rm_inv.is_deleted = 0
			      	     	)
			      ) oa_li
	OUTER APPLY (
	      	SELECT	1 rmi_double
	      	WHERE	@is_deleted = 0
	      			AND	EXISTS (
	      			   		SELECT	1
	      			   		FROM	Material.RawMaterialIncome rmi2
	      			   		WHERE	rmi2.supplier_id = rmi.supplier_id
	      			   				AND	rmi2.suppliercontract_id = rmi.suppliercontract_id
	      			   				AND	rmi2.supply_dt = rmi.supply_dt
	      			   				AND	rmi2.is_deleted = 0
	      			   	)
	      ) rmi_d     	    
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END	
	
	BEGIN TRY
		UPDATE	Material.RawMaterialIncome
		SET 	dt = @dt,
				employee_id = @employee_id,
				is_deleted = @is_deleted
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
						INSERTED.scan_load_dt
				INTO	History.RawMaterialIncome (
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
		WHERE	rv = @rv 				  
		
		
		IF @@ROWCOUNT = 0
		BEGIN
		    RAISERROR('Документ уже кто-то успел поменять. Перечитайте данные и попробуйте записать снова.', 16, 1) 
		    RETURN
		END
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