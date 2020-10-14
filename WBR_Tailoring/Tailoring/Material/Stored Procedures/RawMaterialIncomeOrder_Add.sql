CREATE PROCEDURE [Material].[RawMaterialIncomeOrder_Add]
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
	DECLARE @order_output TABLE (rmio_id INT)        	
	
	SELECT	@error_text = CASE 
	      	                   WHEN rm_inc.doc_id IS NULL THEN 'Поступления материалов с кодом ' + CAST(v.doc_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN rm_inc.rv != @rv THEN 'Документ уже кто-то поменял. Перечитайте данные и попробуйте записать снова.'
	      	                   WHEN rm_inc.is_deleted = 1 THEN 'Поступление материалов удалено'
	      	                   WHEN rmo.rmo_id IS NULL THEN 'Заказа с кодом ' + CAST(@rmo_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN rmo.is_deleted = 1 THEN 'Заказ с кодом ' + CAST(@rmo_id AS VARCHAR(10)) + ' помечен на удаление'
	      	                   WHEN rmio.rmo_id IS NOT NULL THEN 'Заказ с кодом ' + CAST(@rmo_id AS VARCHAR(10)) + ' уже ранее был добавлен в поступление'
	      	              END
	FROM	(VALUES(@doc_id,
			@doc_type_id,
			@rmo_id))v(doc_id,
			doc_type_id,
			rmio_id)   
			LEFT JOIN	Material.RawMaterialIncome rm_inc
				ON	rm_inc.doc_id = v.doc_id
				AND	rm_inc.doc_type_id = v.doc_type_id   
			LEFT JOIN	Suppliers.RawMaterialOrder rmo
				ON	rmo.rmo_id = @rmo_id   
			LEFT JOIN	Material.RawMaterialIncomeOrder rmio
				ON	rmio.doc_id = v.doc_id
				AND	rmio.doc_type_id = v.doc_type_id
				AND	rmio.rmo_id = @rmo_id	
	
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
		
		INSERT Material.RawMaterialIncomeOrder
		  (
		    doc_id,
		    doc_type_id,
		    rmo_id,
		    employee_id,
		    dt
		  )OUTPUT	INSERTED.rmio_id
		   INTO	@order_output (
		   		rmio_id
		   	)
		SELECT	@doc_id,
				@doc_type_id,
				@rmo_id,
				@employee_id,
				@dt
		WHERE	NOT EXISTS (
		     		SELECT	1
		     		FROM	Material.RawMaterialIncomeOrder rmio
		     		WHERE	rmio.doc_id = @doc_id
		     				AND	rmio.doc_type_id = @doc_type_id
		     				AND	rmio.rmo_id = @rmo_id
		     	) 
		
		IF @@ROWCOUNT = 0
		BEGIN
		    RAISERROR('Заказ с кодом %d уже ранее был ранее добавлен в поступление', 16, 1, @rmo_id)
		    RETURN
		END 
		
		COMMIT TRANSACTION
		
		SELECT	inc_o.rv_bigint,
				oo.rmio_id
		FROM	@income_output inc_o   
				CROSS JOIN	@order_output oo
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