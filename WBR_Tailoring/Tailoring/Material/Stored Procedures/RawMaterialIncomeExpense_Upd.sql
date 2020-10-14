CREATE PROCEDURE [Material].[RawMaterialIncomeExpense_Upd]
	@rmie_id INT = NULL,
	@doc_id INT,
	@rv_bigint BIGINT,
	@amount DECIMAL(9, 2),
	@employee_id INT,
	@descript VARCHAR(300)
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @doc_type_id TINYINT = 1,
	        @dt DATETIME2(0) = GETDATE(),
	        @error_text VARCHAR(MAX),
	        @rv ROWVERSION = CAST(@rv_bigint AS ROWVERSION)
	
	DECLARE @income_output TABLE (rv_bigint BIGINT)
	DECLARE @expens_output TABLE (rmie_id INT, create_dt DATETIME2(0))  
	
	SELECT	@error_text = CASE 
	      	                   WHEN rm_inc.doc_id IS NULL THEN 'Поступления материалов с кодом ' + CAST(v.doc_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN rm_inc.rv != @rv THEN 'Документ уже кто-то поменял. Перечитайте данные и попробуйте записать снова.'
	      	                   WHEN rm_inc.is_deleted = 1 THEN 'Поступление материалов удалено'
	      	                   WHEN v.rmie_id IS NOT NULL AND rmie.rmie_id IS NULL THEN 'Доп. затрат с номером ' + CAST(v.rmie_id AS VARCHAR(10)) +
	      	                        ' не существует'
	      	                   WHEN rmie.is_deleted = 1 THEN 'Указанная доп. затрата помечена на удаление.'
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
		END; 
		
		MERGE Material.RawMaterialIncomeExpense t
		USING (
		      	SELECT	@rmie_id rmie_id
		      ) s
				ON s.rmie_id = t.rmie_id
		WHEN  MATCHED  THEN 
		     UPDATE	
		     SET 	t.amount = @amount,
		     		t.employee_id = @employee_id,
		     		t.dt = @dt,
		     		t.descript = @descript
		WHEN NOT MATCHED  THEN 
		     INSERT
		     	(
		     		doc_id,
		     		doc_type_id,
		     		amount,
		     		employee_id,
		     		dt,
		     		descript,
		     		create_dt,
		     		create_employee_id,
		     		is_deleted
		     	)
		     VALUES
		     	(
		     		@doc_id,
		     		@doc_type_id,
		     		@amount,
		     		@employee_id,
		     		@dt,
		     		@descript,
		     		@dt,
		     		@employee_id,
		     		0
		     	)
		     OUTPUT	INSERTED.rmie_id,
		     		INSERTED.create_dt
		     INTO	@expens_output (
		     		rmie_id,
		     		create_dt
		     	); 
		
		COMMIT TRANSACTION
		
		SELECT	inc_o.rv_bigint,
				CAST(exp_o.create_dt AS DATETIME) create_dt,
				exp_o.rmie_id
		FROM	@income_output inc_o   
				CROSS JOIN	@expens_output exp_o
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