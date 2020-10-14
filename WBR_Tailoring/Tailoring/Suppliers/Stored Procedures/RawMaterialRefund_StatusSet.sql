CREATE PROCEDURE [Suppliers].[RawMaterialRefund_StatusSet]
	@rmr_id INT,
	@rmrs_id INT,
	@rv_bigint BIGINT,
	@employee_id INT
AS
	SET NOCOUNT ON
	
	DECLARE @dt             DATETIME2(0) = GETDATE(),
	        @rv             ROWVERSION = CAST(@rv_bigint AS ROWVERSION),
	        @error_text     VARCHAR(MAX)
	
	SELECT	@error_text = CASE 
	      	                   WHEN rmr.rmr_id IS NULL THEN 'Возврата поставщику № ' + CAST(v.rmr_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN rmrs.rmrs_id IS NULL THEN 'Статуса с ИД ' + CAST(v.rmrs_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN rmr.rv != @rv THEN 'Документ уже кто-то поменял. Перечитайте данные и попробуйте записать снова.'
	      	                   WHEN rmr.is_deleted = 1 THEN 'Возврат поставщику № ' + CAST(v.rmr_id AS VARCHAR(10)) + ' удален'
	      	                   WHEN v.rmrs_id = rmr.rmrs_id THEN 'Документ уже находится в статусе: ' + rmrs.rmrs_name
	      	              END
	FROM	(VALUES(@rmr_id,
			@rmrs_id))v(rmr_id,
			rmrs_id)   
			LEFT JOIN	Suppliers.RawMaterialRefund rmr
				ON	rmr.rmr_id = v.rmr_id   
			LEFT  JOIN	Suppliers.RawMaterialRefundStatus rmrs
				ON	rmrs.rmrs_id = v.rmrs_id							
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END	
	
	BEGIN TRY
		UPDATE	Suppliers.RawMaterialRefund
		SET 	rmrs_id = @rmrs_id,
				dt = @dt,
				employee_id = @employee_id
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
		    RAISERROR('Не удалось обновить статус, возможно его кто-то уже поменял', 16, 1)
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