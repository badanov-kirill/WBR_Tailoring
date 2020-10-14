CREATE PROCEDURE [Material].[RawMaterialInvoiceDetail_AmountCurSet]
	@doc_id INT,
	@rv_bigint BIGINT,
	@employee_id INT,
	@data_tab dbo.AmountList READONLY
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	
	DECLARE @doc_type_id TINYINT = 1,
	        @dt DATETIME2(0) = GETDATE(),
	        @error_text VARCHAR(MAX),
	        @rv ROWVERSION = CAST(@rv_bigint AS ROWVERSION),
	        @rub_currency_id INT = 1
	
	DECLARE @income_output TABLE (rv_bigint BIGINT)
	
	SELECT	@error_text = CASE 
	      	                   WHEN rm_inc.doc_id IS NULL THEN 'Поступления материалов с кодом ' + CAST(v.doc_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN rm_inc.rv != @rv THEN 'Документ уже кто-то поменял. Перечитайте данные и попробуйте записать снова.'
	      	                   WHEN rm_inc.is_deleted = 1 THEN 'Поступление материалов удалено'
	      	                   WHEN rm_inc.rmis_id >= 7 THEN 'Документ закрыт, редактировать нельзя'
	      	                   --WHEN sc.currency_id = @rub_currency_id THEN 'Для рублевого доровора не нужно указывать валютные суммы'
	      	              END
	FROM	(VALUES(@doc_id,
			@doc_type_id))v(doc_id,
			doc_type_id)   
			LEFT JOIN	Material.RawMaterialIncome rm_inc   
			INNER JOIN	Suppliers.SupplierContract sc
				ON	sc.suppliercontract_id = rm_inc.suppliercontract_id
				ON	rm_inc.doc_id = v.doc_id
				AND	rm_inc.doc_type_id = v.doc_type_id   
			LEFT JOIN	Material.RawMaterialInvoice rmi
				ON	rmi.doc_id = rm_inc.doc_id
				AND	rmi.doc_type_id = rm_inc.doc_type_id
	
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s.', 16, 1, @error_text)
	    RETURN
	END	
	
	SELECT	@error_text = CASE 
	      	                   WHEN rmid.rmid_id IS NULL THEN 'Детали УПД с кодом ' + CAST(dt.id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN rmi.doc_id != @doc_id THEN 'Деталm УПД с кодом ' + CAST(dt.id AS VARCHAR(10)) + ' относится к другому документу с номером ' 
	      	                        + CAST(rmi.doc_id AS VARCHAR(10))
	      	                   ELSE NULL
	      	              END
	FROM	@data_tab dt   
			LEFT JOIN	Material.RawMaterialInvoiceDetail rmid   
			INNER  JOIN	Material.RawMaterialInvoice rmi
				ON	rmi.rmi_id = rmid.rmi_id
				ON	rmid.rmid_id = dt.id
	WHERE	rmid.rmid_id IS NULL
			OR	rmi.doc_id != @doc_id	
			
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s.', 16, 1, @error_text)
	    RETURN
	END	
	
	BEGIN TRY
		BEGIN TRANSACTION 	
		
		UPDATE	Material.RawMaterialIncome
		SET 	employee_id = @employee_id,
				dt = @dt
				OUTPUT	CAST(INSERTED.rv AS BIGINT)
				INTO	@income_output (
						rv_bigint
					)
		WHERE	doc_id = @doc_id
				AND	doc_type_id = @doc_type_id
				AND	rv = @rv	
		
		IF @@ROWCOUNT = 0
		BEGIN
		    RAISERROR('Документ уже кто-то успел поменять. Перечитайте данные и попробуйте записать снова.', 16, 1)
		    RETURN
		END 
		
		;WITH cte_target AS (
			SELECT	rmid.rmid_id,
					rmid.amount_cur_with_nds
			FROM	Material.RawMaterialInvoiceDetail rmid   
					INNER JOIN	Material.RawMaterialInvoice rmi
						ON	rmi.rmi_id = rmid.rmi_id
			WHERE	rmi.doc_id = @doc_id
					AND	rmi.doc_type_id = @doc_type_id
		)		
		MERGE cte_target t
		USING @data_tab s
				ON t.rmid_id = s.id
		WHEN MATCHED THEN 
		     UPDATE	
		     SET 	t.amount_cur_with_nds = s.amount
		WHEN NOT MATCHED BY SOURCE THEN 
		     UPDATE	
		     SET 	t.amount_cur_with_nds = NULL;
		
		COMMIT TRANSACTION
		
		SELECT	inc_o.rv_bigint
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