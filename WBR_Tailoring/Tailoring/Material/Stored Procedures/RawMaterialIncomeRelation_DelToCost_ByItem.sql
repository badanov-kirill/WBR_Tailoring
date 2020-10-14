CREATE PROCEDURE [Material].[RawMaterialIncomeRelation_DelToCost_ByItem]
	@doc_id INT,
	@rv_bigint BIGINT,
	@employee_id INT,
	@rm_invd_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @doc_type_id TINYINT = 1,
	        @dt DATETIME2(0) = GETDATE(),
	        @rv ROWVERSION = CAST(@rv_bigint AS ROWVERSION),
	        @error_text VARCHAR(MAX)
	DECLARE @proc_id INT	
	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID
	
	DECLARE @income_output TABLE (rv_bigint BIGINT)
	DECLARE @income_detail_output TABLE (shkrm_id INT, amount DECIMAL(19, 8))   
	DECLARE @output_raw_material_invoice_relation_detail TABLE(rmid_id INT, amount DECIMAL(19, 8))          	
	
	SELECT	@error_text = CASE 
	      	                   WHEN rm_inc.rv != @rv THEN 'Документ уже кто-то поменял. Перечитайте данные и попробуйте записать снова.'
	      	                   WHEN rm_inc.doc_id IS NULL THEN 'Поступления материалов с кодом ' + CAST(v.doc_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN rm_inc.is_deleted = 1 THEN 'Поступление материалов удалено'
	      	                   WHEN rm_inc.rmis_id NOT IN (1, 2, 3, 4, 5, 6) THEN 'Статус документа ' + rmis.rmis_name + ' не позволяет удаления распределения'
	      	                   WHEN oa.rmid_id IS NULL THEN 'У документа не существует детали инвойса с кодом ' + CAST(@rm_invd_id AS VARCHAR(10))
	      	              END
	FROM	(VALUES(@doc_id,
			@doc_type_id))v(doc_id,
			doc_type_id)   
			LEFT JOIN	Material.RawMaterialIncome rm_inc
				ON	rm_inc.doc_id = v.doc_id
				AND	rm_inc.doc_type_id = v.doc_type_id   
			INNER JOIN	Material.RawMaterialIncomeStatus rmis
				ON	rmis.rmis_id = rm_inc.rmis_id   
			OUTER APPLY (
			      	SELECT	rmid.rmid_id
			      	FROM	Material.RawMaterialInvoice rmi   
			      			INNER JOIN	Material.RawMaterialInvoiceDetail rmid
			      				ON	rmid.rmi_id = rmi.rmi_id
			      	WHERE	rmi.doc_id = rm_inc.doc_id
			      			AND	rmi.doc_type_id = rm_inc.doc_type_id
			      			AND	rmid.rmid_id = @rm_invd_id
			      ) oa			      	
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('(%s) данные не загружены, проверьте файл.', 16, 1, @error_text)
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
		
		DELETE	Material.RawMaterialInvoiceRelationDetail
		      	OUTPUT	DELETED.rmid_id,
		      			DELETED.amount
		      	INTO	@output_raw_material_invoice_relation_detail (
		      			rmid_id,
		      			amount
		      		)
		WHERE	doc_id = @doc_id
				AND	doc_type_id = @doc_type_id
				AND	rm_invd_id = @rm_invd_id
		
		UPDATE	rmid
		SET 	amount = rmid.amount - ormird.amount
		    	OUTPUT	INSERTED.shkrm_id,
		    			INSERTED.amount
		    	INTO	@income_detail_output (
		    			shkrm_id,
		    			amount
		    		)
		FROM	Material.RawMaterialIncomeDetail rmid
				INNER JOIN	@output_raw_material_invoice_relation_detail ormird
					ON	ormird.rmid_id = rmid.rmid_id
							
		UPDATE	sma
		SET 	amount = ido.amount
		OUTPUT	INSERTED.shkrm_id,		   		
		   			INSERTED.stor_unit_residues_okei_id,
		   			INSERTED.stor_unit_residues_qty,
		   			INSERTED.amount,
		   			INSERTED.gross_mass,	   		
		   			@proc_id,
		   			@dt,
		   			@employee_id
		   		
			   INTO	History.SHKRawMaterialAmount (
		   			shkrm_id,		   		
		   			stor_unit_residues_okei_id,
		   			stor_unit_residues_qty,
		   			amount,
		   			gross_mass,
		   			proc_id,
		   			dt,
		   			employee_id		   		
		   		)
		FROM	Warehouse.SHKRawMaterialAmount sma
				INNER JOIN	@income_detail_output ido
					ON	ido.shkrm_id = sma.shkrm_id
					
		
		COMMIT TRANSACTION
		
		SELECT	rv_bigint
		FROM	@income_output
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