CREATE PROCEDURE [Suppliers].[RawMaterialRefundSuspectDetail_Add]
	@rmr_id INT,
	@shks_id INT,
	@employee_id INT,
	@rv_bigint BIGINT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE(),
	        @rv ROWVERSION = CAST(@rv_bigint AS ROWVERSION),
	        @qty DECIMAL(9, 3),
	        @okei_id INT,
	        @shksu_id INT,
	        @descript VARCHAR(900),
	        @error_text VARCHAR(MAX)
	
	DECLARE @refund_output TABLE (rv_bigint BIGINT)	      
	
	SELECT	@error_text = CASE 
	      	                   WHEN rmr.rmr_id IS NULL THEN 'Возврата поставщику № ' + CAST(v.rmr_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN rmr.is_deleted = 1 THEN 'Возврат поставщику № ' + CAST(v.rmr_id AS VARCHAR(10)) + ' помечен на удаление'
	      	                   WHEN rmr.rv != @rv THEN 'Документ уже кто-то поменял. Перечитайте данные и попробуйте записать снова.'
	      	                   WHEN ss.shks_id IS NULL THEN 'Некоректный ШК ' + CAST(v.shks_id AS VARCHAR(10)) + ' для обезличенного товара '
	      	                   WHEN ssu.shks_id IS NULL THEN 'Данный ШК ' + CAST(v.shks_id AS VARCHAR(10)) + '  не был описан для безличенного товара'
	      	                   WHEN rmrsd.rmrsd_id IS NOT NULL THEN 'Данный ШК ' + CAST(v.shks_id AS VARCHAR(10)) + ' уже запикан в документ № ' + CAST(rmrsd.rmr_id AS VARCHAR(10))
	      	              END,
			@qty          = ssu.qty,
			@okei_id      = ssu.okei_id,
			@shksu_id     = ssu.shksu_id,
			@descript     = ssu.descript
	FROM	(VALUES(@rmr_id,
			@shks_id))v(rmr_id,
			shks_id)   
			LEFT JOIN	Suppliers.RawMaterialRefund rmr
				ON	rmr.rmr_id = v.rmr_id   
			LEFT JOIN	Warehouse.SHKSuspect ss
				ON	ss.shks_id = v.shks_id   
			LEFT JOIN	Warehouse.SHKSuspectUnit ssu
				ON	ssu.shks_id = v.shks_id   
			LEFT JOIN	Suppliers.RawMaterialRefundSuspectDetail rmrsd
				ON	rmrsd.shks_id = v.shks_id		  								    			    
	
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
		
		INSERT Suppliers.RawMaterialRefundSuspectDetail
		  (
		    rmr_id,
		    shks_id,
		    qty,
		    okei_id,
		    is_deleted,
		    dt,
		    employee_id
		  )
		VALUES
		  (
		    @rmr_id,
		    @shks_id,
		    @qty,
		    @okei_id,
		    0,
		    @dt,
		    @employee_id
		  ) 
		
		COMMIT TRANSACTION
		
		SELECT	ro.rv_bigint,
				@shks_id                  shks_id,
				@qty                      qty,
				@okei_id                  okei_id,
				o.fullname                okei_name,
				@shksu_id                 shksu_id,
				su.su_name,
				@descript                 descript,
				CAST(@dt AS DATETIME)     dt
		FROM	@refund_output ro   
				INNER JOIN	Qualifiers.OKEI o
					ON	o.okei_id = @okei_id   
				INNER JOIN	Warehouse.SHKSpaceUnit ssu   
				INNER JOIN	RefBook.SpaceUnit su
					ON	su.su_id = ssu.su_id
					ON	ssu.shksu_id = @shksu_id
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