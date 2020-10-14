CREATE PROCEDURE [Material].[RawMaterialIncomeOrderToSupplier_Del]
	@doc_id INT,
	@ots_id INT,
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
	      	                   --WHEN rm_inc.rmis_id >= 7 THEN 'Документ закрыт, редактировать нельзя'
	      	                   WHEN ots.ots_id IS NULL THEN 'Заказа с кодом ' + CAST(@ots_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN rm_inc.ots_id IS NULL THEN 'Заказа с кодом ' + CAST(@ots_id AS VARCHAR(10)) + '  нет в поступлении'
	      	              END
	FROM	(VALUES(@doc_id,
			@doc_type_id,
			@ots_id))v(doc_id,
			doc_type_id,
			ots_id)   
			LEFT JOIN	Material.RawMaterialIncome rm_inc
				ON	rm_inc.doc_id = v.doc_id
				AND	rm_inc.doc_type_id = v.doc_type_id   
			LEFT JOIN	Material.OrderToSupplier ots
				ON	ots.ots_id = v.ots_id   
			
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('(%s).', 16, 1, @error_text)
	    RETURN
	END	
	
	BEGIN TRY
		BEGIN TRANSACTION 	
		
		UPDATE	Material.RawMaterialIncome
		SET 	employee_id = @employee_id,
				dt = @dt,
				ots_id = NULL
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