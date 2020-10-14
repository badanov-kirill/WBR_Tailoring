CREATE PROCEDURE [Material].[RawMaterialIncomeRelation_DelToReservOperation]
	@doc_id INT,
	@rv_bigint VARCHAR(20),
	@operation_num INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @doc_type_id TINYINT = 1,
	        @dt DATETIME2(0) = GETDATE(),
	        @rv ROWVERSION = CAST(CAST(@rv_bigint AS BIGINT) AS ROWVERSION),
	        @error_text VARCHAR(MAX)
	
	DECLARE @proc_id INT	
	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID
	DECLARE @income_output TABLE (rv_bigint VARCHAR(20)) 
	DECLARE @reserv_output TABLE (rmid_id INT, spcvc_id INT, quantity DECIMAL(12, 3))            	
	
	SELECT	@error_text = CASE 
	      	                   WHEN rm_inc.rv != @rv THEN 'Документ уже кто-то поменял. Перечитайте данные и попробуйте записать снова.'
	      	                   WHEN rm_inc.doc_id IS NULL THEN 'Поступления материалов с кодом ' + CAST(v.doc_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN rm_inc.is_deleted = 1 THEN 'Поступление материалов удалено'
	      	                   WHEN rm_inc.rmis_id NOT IN (1,2,3,4,5,6) THEN 'Статус документа ' + rmis.rmis_name +  ' не позволяет удаления распределения'
	      	              END
	FROM	(VALUES(@doc_id,
			@doc_type_id))v(doc_id,
			doc_type_id)   
			LEFT JOIN	Material.RawMaterialIncome rm_inc
				ON	rm_inc.doc_id = v.doc_id
				AND	rm_inc.doc_type_id = v.doc_type_id  			
			INNER JOIN Material.RawMaterialIncomeStatus rmis
				ON rmis.rmis_id = rm_inc.rmis_id
	
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
				OUTPUT	CAST(CAST(INSERTED.rv AS BIGINT) AS VARCHAR(20))
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
		
		DELETE	Material.RawMaterialIncomeOrderRelationDetail
		WHERE	doc_id = @doc_id
				AND	doc_type_id = @doc_type_id
				AND operation_num = @operation_num
		
		DELETE	Material.RawMaterialIncomeOrderReservRelationDetail
		      	OUTPUT	DELETED.rmid_id,
		      			DELETED.spcvc_id,
		      			DELETED.quantity
		      	INTO	@reserv_output (
		      			rmid_id,
		      			spcvc_id,
		      			quantity
		      		)
		WHERE	doc_id = @doc_id
				AND	doc_type_id = @doc_type_id
				AND operation_num = @operation_num;
		
		MERGE Warehouse.SHKRawMaterialReserv t
		USING (
		      	SELECT	ro.spcvc_id,
		      			ro.quantity,
		      			rmid.shkrm_id
		      	FROM	@reserv_output ro   
		      			INNER JOIN	Material.RawMaterialIncomeDetail rmid
		      				ON	rmid.rmid_id = ro.rmid_id
		      ) s
				ON t.shkrm_id = s.shkrm_id
				AND t.spcvc_id = s.spcvc_id
		WHEN MATCHED AND t.quantity <> s.quantity THEN 
		     UPDATE	
		     SET 	t.quantity = t.quantity - s.quantity,
		     		t.dt = @dt,
		     		t.employee_id = @employee_id
		WHEN MATCHED AND t.quantity = s.quantity THEN 
		     DELETE	OUTPUT	ISNULL(INSERTED.shkrm_id, DELETED.shkrm_id),
		           			ISNULL(INSERTED.spcvc_id, DELETED.spcvc_id),
		           			ISNULL(INSERTED.okei_id, DELETED.okei_id),
		           			ISNULL(INSERTED.quantity, DELETED.quantity),
		           			@dt,
		           			@employee_id,
		           			ISNULL(INSERTED.rmid_id, DELETED.rmid_id),
		           			ISNULL(INSERTED.rmodr_id, DELETED.rmodr_id),
		           			@proc_id,
		           			UPPER(LEFT($action, 1))
		           	INTO	History.SHKRawMaterialReserv (
		           			shkrm_id,
		           			spcvc_id,
		           			okei_id,
		           			quantity,
		           			dt,
		           			employee_id,
		           			rmid_id,
		           			rmodr_id,
		           			proc_id,
		           			operation
		           		); 
		
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