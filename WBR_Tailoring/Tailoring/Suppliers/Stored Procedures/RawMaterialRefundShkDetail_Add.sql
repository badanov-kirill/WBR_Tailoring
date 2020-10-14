CREATE PROCEDURE [Suppliers].[RawMaterialRefundShkDetail_Add]
	@rmr_id INT,
	@shkrm_id INT,
	@employee_id INT,
	@rv_bigint BIGINT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE(),
	        @rv ROWVERSION = CAST(@rv_bigint AS ROWVERSION),
	        @doc_type_id TINYINT = 1,
	        @qty DECIMAL(9, 3),
	        @okei_id INT,
	        @descr VARCHAR(900),
	        @error_text VARCHAR(MAX)
	
	DECLARE @refund_output TABLE (rv_bigint BIGINT) 
	
	DECLARE @shk_detail TABLE (
	        	rmid_id INT NULL,
	        	rmt_id INT NOT NULL,
	        	art_id INT NOT NULL,
	        	color_id INT NOT NULL,
	        	stor_unit_residues_okei_id INT NOT NULL,
	        	stor_unit_residues_qty DECIMAL(9, 3) NOT NULL,
	        	frame_width SMALLINT NULL
	        )     	
	
	SELECT	@error_text = CASE 
	      	                   WHEN smai.shkrm_id IS NULL THEN 'ШК ' + CAST(v.shkrm_id AS VARCHAR(10)) + ' ранее не был описан'
	      	                   WHEN rmr.rmr_id IS NULL THEN 'Возврата поставщику № ' + CAST(v.rmr_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN rmr.is_deleted = 1 THEN 'Возврат поставщику № ' + CAST(v.rmr_id AS VARCHAR(10)) + ' помечен на удаление'
	      	                   WHEN rmr.rv != @rv THEN 'Документ уже кто-то поменял. Перечитайте данные и попробуйте записать снова.'
	      	                  -- WHEN srmdd.shkrm_id IS NULL THEN 'ШК ' + CAST(v.shkrm_id AS VARCHAR(10)) + ' ранее не был описан как дефектный'
	      	                   WHEN rmrsd.rmrsd_id IS NOT NULL AND rmrsd.rmid_id = rmid.rmid_id THEN 'Данный ШК ' + CAST(v.shkrm_id AS VARCHAR(10)) +
	      	                        ' уже запикан в документ № ' + CAST(rmrsd.rmr_id AS VARCHAR(10))
	      	              END,
			@okei_id = smai.okei_id,
			@qty = smai.qty,
			@descr = srmdd.descr
	FROM	(VALUES(@rmr_id,
			@shkrm_id))v(rmr_id,
			shkrm_id)   
			LEFT JOIN	Suppliers.RawMaterialRefund rmr
				ON	rmr.rmr_id = v.rmr_id   
			LEFT JOIN	Warehouse.SHKRawMaterialDefectDescr srmdd
				ON	srmdd.shkrm_id = v.shkrm_id   
			LEFT JOIN	Suppliers.RawMaterialRefundShkDetail rmrsd
				ON	rmrsd.shkrm_id = v.shkrm_id
				AND	rmrsd.is_deleted = 0   
			LEFT JOIN	Material.RawMaterialIncomeDetail rmid
				ON	rmid.shkrm_id = v.shkrm_id	
			LEFT JOIN Warehouse.SHKRawMaterialActualInfo smai
				ON smai.shkrm_id = v.shkrm_id 
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	INSERT @shk_detail
	  (
	    rmid_id,
	    rmt_id,
	    art_id,
	    color_id,
	    stor_unit_residues_okei_id,
	    stor_unit_residues_qty,
	    frame_width
	  )
	SELECT	rmid.rmid_id,
			smai.rmt_id,
			smai.art_id,
			smai.color_id,
			smai.stor_unit_residues_okei_id,
			smai.stor_unit_residues_qty,
			smai.frame_width
	FROM	Warehouse.SHKRawMaterialActualInfo smai   
			LEFT JOIN	Material.RawMaterialIncomeDetail rmid
				ON	rmid.doc_id = smai.doc_id
				AND	rmid.doc_type_id = @doc_type_id
				AND	rmid.shkrm_id = smai.shkrm_id
	WHERE	smai.shkrm_id = @shkrm_id		
	
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
		
		INSERT Suppliers.RawMaterialRefundShkDetail
		  (
		    rmr_id,
		    rmid_id,
		    shkrm_id,
		    rmt_id,
		    art_id,
		    color_id,
		    qty,
		    okei_id,
		    stor_unit_residues_okei_id,
		    stor_unit_residues_qty,
		    frame_width,
		    is_deleted,
		    dt,
		    employee_id
		  )
		SELECT	@rmr_id         rmr_id,
				sd.rmid_id,
				@shkrm_id       shkrm_id,
				sd.rmt_id,
				sd.art_id,
				sd.color_id,
				@qty            qty,
				@okei_id        okei_id,
				sd.stor_unit_residues_okei_id,
				sd.stor_unit_residues_qty,
				sd.frame_width,
				0               is_deleted,
				@dt,
				@employee_id
		FROM	@shk_detail     sd 
		
		COMMIT TRANSACTION
		
		SELECT	rv_bigint,
				@shkrm_id                 shkrm_id,
				@qty                      qty,
				@okei_id                  okei_id,
				o.fullname                okei_name,
				sd.frame_width,
				rmt.rmt_name,
				a.art_name,
				cc.color_name,
				rmid.doc_id,
				@descr                    descr,
				CAST(@dt AS DATETIME)     dt
		FROM	@refund_output   
				CROSS JOIN	@shk_detail sd   
				CROSS JOIN	Qualifiers.OKEI o   
				INNER  JOIN	Material.RawMaterialType rmt
					ON	rmt.rmt_id = sd.rmt_id   
				INNER  JOIN	Material.ClothColor cc
					ON	cc.color_id = sd.color_id   
				INNER  JOIN	Material.Article a
					ON	a.art_id = sd.art_id   
				LEFT JOIN	Material.RawMaterialIncomeDetail rmid
					ON	rmid.rmid_id = sd.rmid_id
		WHERE	o.okei_id = @okei_id
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