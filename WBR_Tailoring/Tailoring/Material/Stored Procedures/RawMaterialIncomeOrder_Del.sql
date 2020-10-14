CREATE PROCEDURE Material.RawMaterialIncomeOrder_Del
	@doc_id INT,
	@rmo_id INT,
	@rv_bigint BIGINT,
	@employee_id INT
AS
	SET NOCOUNT ON 
	SET XACT_ABORT ON
	
	DECLARE @doc_type_id TINYINT = 1,
	        @dt DATETIME2(0) = GETDATE(),
	        @error_text VARCHAR(MAX),
	        @rv ROWVERSION = CAST(@rv_bigint AS ROWVERSION)
	
	DECLARE @income_output TABLE (rv_bigint BIGINT)        	
	
	SELECT	@error_text = CASE 
	      	                   WHEN rm_inc.doc_id IS NULL THEN 'Поступления материалов с кодом ' + CAST(v.doc_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN rm_inc.rv != @rv THEN 'Документ уже кто-то поменял. Перечитайте данные и попробуйте записать снова.'
	      	                   WHEN rm_inc.is_deleted = 1 THEN 'Поступление материалов удалено'
	      	                   WHEN rmo.rmo_id IS NULL THEN 'Заказа с кодом ' + CAST(@rmo_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN rmio.rmo_id IS NULL THEN 'Заказ с кодом ' + CAST(@rmo_id AS VARCHAR(10)) + ' отсутствует у поступления'
	      	                   WHEN rel.r IS NOT NULL THEN 'Удалить заказ нельзя, т.к. поступление уже было распределено'
	      	              END
	FROM	(VALUES(@doc_id,
			@doc_type_id,
			@rmo_id))v(doc_id,
			doc_type_id,
			rmo_id)   
			LEFT JOIN	Material.RawMaterialIncome rm_inc
				ON	rm_inc.doc_id = v.doc_id
				AND	rm_inc.doc_type_id = v.doc_type_id   
			LEFT JOIN	Suppliers.RawMaterialOrder rmo
				ON	rmo.rmo_id = @rmo_id   
			LEFT JOIN	Material.RawMaterialIncomeOrder rmio
				ON	rmio.doc_id = v.doc_id
				AND	rmio.doc_type_id = v.doc_type_id
				AND	rmio.rmo_id = @rmo_id   
			OUTER APPLY (
			      	SELECT	1 r
			      	WHERE	EXISTS (
			      	     		SELECT	1 r
			      	     		FROM	Material.RawMaterialIncomeOrderRelationDetail rmiord
			      	     		WHERE	rmiord.doc_id = v.doc_id
			      	     				AND	rmiord.doc_type_id = v.doc_type_id
			      	     		UNION ALL		      	     		
			      	     		SELECT	1 r
			      	     		FROM	Material.RawMaterialIncomeOrderReservRelationDetail rmiorrd
			      	     		WHERE	rmiorrd.doc_id = v.doc_id
			      	     				AND	rmiorrd.doc_type_id = v.doc_type_id
			      	     	)
			      )rel										
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('(%s).', 16, 1, @error_text)
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
		
		DELETE	Material.RawMaterialIncomeOrder
		WHERE	doc_id = @doc_id
				AND	doc_type_id = @doc_type_id
				AND	rmo_id = @rmo_id 
		
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