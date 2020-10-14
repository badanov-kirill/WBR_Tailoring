CREATE PROCEDURE [Suppliers].[RawMaterialRefundShkDetail_Del]
	@rmr_id INT,
	@shkrm_id INT,
	@employee_id INT,
	@rv_bigint BIGINT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE(),
	        @rv ROWVERSION = CAST(@rv_bigint AS ROWVERSION),
	        @error_text VARCHAR(MAX)
	
	DECLARE @refund_output TABLE (rv_bigint BIGINT)	      
	
	SELECT	@error_text = CASE 
	      	                   WHEN rmr.rmr_id IS NULL THEN 'Возврата поставщику № ' + CAST(v.rmr_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN rmr.is_deleted = 1 THEN 'Возврат поставщику № ' + CAST(v.rmr_id AS VARCHAR(10)) + ' помечен на удаление'
	      	                   WHEN rmr.rv != @rv THEN 'Документ уже кто-то поменял. Перечитайте данные и попробуйте записать снова.'
	      	                   WHEN srmdd.shkrm_id IS NULL THEN 'ШК ' + CAST(v.shkrm_id AS VARCHAR(10)) + ' ранее не был описан как дефектный'
	      	                   WHEN rmrsd.rmrsd_id IS NULL THEN 'Данный ШК ' + CAST(v.shkrm_id AS VARCHAR(10)) + ' отсутствует у документа № ' + CAST(v.rmr_id AS VARCHAR(10))
	      	                   WHEN rmrsd.is_deleted = 1 THEN 'Данный ШК ' + CAST(v.shkrm_id AS VARCHAR(10)) + ' уже удален у документа № ' + CAST(v.rmr_id AS VARCHAR(10))
	      	              END
	FROM	(VALUES(@rmr_id,
			@shkrm_id))v(rmr_id,
			shkrm_id)   
			LEFT JOIN	Suppliers.RawMaterialRefund rmr
				ON	rmr.rmr_id = v.rmr_id   
			LEFT JOIN	Warehouse.SHKRawMaterialDefectDescr srmdd
				ON	srmdd.shkrm_id = v.shkrm_id   
			LEFT JOIN	Suppliers.RawMaterialRefundShkDetail rmrsd
				ON	rmrsd.rmr_id = v.rmr_id
				AND	rmrsd.shkrm_id = v.shkrm_id						    			    
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END		
	
	BEGIN TRY
		BEGIN TRANSACTION 
		
		UPDATE	Suppliers.RawMaterialRefund
		SET 	dt = @dt,
				employee_id = @employee_id
				OUTPUT	CAST(INSERTED.rv AS BIGINT)
				INTO	@refund_output (
						rv_bigint
					)
		WHERE	rv = @rv 	
		
		IF @@ROWCOUNT = 0
		BEGIN
		    RAISERROR('Повторите попытку, документ уже кто-то поменял', 16, 1)
		    RETURN
		END		
		
		UPDATE	Suppliers.RawMaterialRefundShkDetail
		SET 	is_deleted = 1,
				dt = @dt,
				employee_id = @employee_id
		WHERE	shkrm_id = @shkrm_id 
		
		COMMIT TRANSACTION
		
		SELECT	rv_bigint
		FROM	@refund_output
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