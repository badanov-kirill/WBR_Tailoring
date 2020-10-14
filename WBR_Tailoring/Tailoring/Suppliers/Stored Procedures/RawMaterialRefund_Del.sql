CREATE PROCEDURE [Suppliers].[RawMaterialRefund_Del]
	@rmr_id INT,
	@is_deleted BIT = 1,
	@employee_id INT,
	@rv_bigint BIGINT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt             DATETIME2(0) = GETDATE(),
	        @rv             ROWVERSION = CAST(@rv_bigint AS ROWVERSION),
	        @error_text     VARCHAR(MAX)
	
	SELECT	@error_text = CASE 
	      	                   WHEN rmr.rmr_id IS NULL THEN 'Возврата поставщику № ' + CAST(v.rmr_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN rmr.rv != @rv THEN 'Документ уже кто-то поменял. Перечитайте данные и попробуйте записать снова.'
	      	                   WHEN rmr.is_deleted = @is_deleted THEN 'Не верно передан флаг пометки удаления для Возврата поставщику № ' + CAST(v.rmr_id AS VARCHAR(10))
	      	                   WHEN rmr_d.rmr_double IS NOT NULL THEN 'Уже существует возврат по поставщику ИД ' + CAST(rmr.supplier_id AS VARCHAR(10)) 
	      	                        + ' и договору ИД ' + CAST(rmr.suppliercontract_id AS VARCHAR(10)) + ' на дату поставки: ' + CONVERT(VARCHAR(30), rmr.sending_dt, 120)
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@rmr_id))v(rmr_id)   
			LEFT JOIN	Suppliers.RawMaterialRefund rmr
				ON	rmr.rmr_id = v.rmr_id   
			OUTER APPLY (
			      	SELECT	1 rmr_double
			      	WHERE	@is_deleted = 0
			      			AND	EXISTS (
			      			   		SELECT	1
			      			   		FROM	Suppliers.RawMaterialRefund rmr2
			      			   		WHERE	rmr2.supplier_id = rmr.supplier_id
			      			   				AND	rmr2.suppliercontract_id = rmr.suppliercontract_id
			      			   				AND	rmr2.sending_dt = rmr.sending_dt
			      			   				AND	rmr2.is_deleted = 0
			      			   	)
			      ) rmr_d		   	    
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END	
	
	BEGIN TRY
		UPDATE	Suppliers.RawMaterialRefund
		SET 	dt = @dt,
				employee_id = @employee_id,
				is_deleted = @is_deleted
				OUTPUT	INSERTED.rmr_id,
						INSERTED.supplier_id,
						INSERTED.suppliercontract_id,
						INSERTED.rmrs_id,
						INSERTED.sending_dt,
						INSERTED.is_deleted,
						INSERTED.dt,
						INSERTED.employee_id,
						INSERTED.comment
				INTO	History.RawMaterialRefund (
						rmr_id,
						supplier_id,
						suppliercontract_id,
						rmrs_id,
						sending_dt,
						is_deleted,
						dt,
						employee_id,
						comment
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
GO 	