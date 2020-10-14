CREATE PROCEDURE [Material].[RawMaterialIncomeExpense_Del]
	@rmie_id INT,
	@doc_id INT,
	@rv_bigint BIGINT,
	@is_deleted BIT,
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
	      	                   WHEN v.rmie_id IS NOT NULL AND rmie.rmie_id IS NULL THEN 'Доп. затрат с номером ' + CAST(v.rmie_id AS VARCHAR(10)) +
	      	                        ' не существует'
	      	                   WHEN rmie.is_deleted = @is_deleted THEN 'Не верный признак пометки удаления.'
	      	                   WHEN rmie.rmie_id IS NOT NULL AND v.doc_id <> rmie.doc_id THEN 'Доп. затрате с номером ' + CAST(v.rmie_id AS VARCHAR(10)) +
	      	                        ' соответствует документу поступления ' + CAST(rmie.doc_id AS VARCHAR(10)) + ', а передается ' + CAST(v.doc_id AS VARCHAR(10))
	      	              END
	FROM	(VALUES(@doc_id,
			@doc_type_id,
			@rmie_id))v(doc_id,
			doc_type_id,
			rmie_id)   
			LEFT JOIN	Material.RawMaterialIncome rm_inc
				ON	rm_inc.doc_id = v.doc_id
				AND	rm_inc.doc_type_id = v.doc_type_id   
			LEFT JOIN	Material.RawMaterialIncomeExpense rmie
				ON	rmie.rmie_id = v.rmie_id			 					 
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('(%s).', 16, 1, @error_text)
	    RETURN
	END	
	
	IF EXISTS (
	   	SELECT	1
	   	FROM	Material.RawMaterialIncomeExpenseRelationDetail rmierd
	   	WHERE	rmierd.rmie_id = @rmie_id
	   )
	BEGIN
	    RAISERROR('По доп. затрате уже проведено распределение', 16, 1)
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
		
		UPDATE	Material.RawMaterialIncomeExpense
		SET 	is_deleted = @is_deleted,
				employee_id = @employee_id,
				dt = @dt
		WHERE	rmie_id = @rmie_id 
		
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