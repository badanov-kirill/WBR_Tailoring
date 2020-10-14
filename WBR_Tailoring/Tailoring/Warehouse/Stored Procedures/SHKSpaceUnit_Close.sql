CREATE PROCEDURE [Warehouse].[SHKSpaceUnit_Close]
	@shksu_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @with_log BIT = 1
	DECLARE @rmi_status_accept TINYINT = 4 -- Приемка
	DECLARE @rmi_status_end_income TINYINT = 5 --Приемка завершена
	DECLARE @doc_id INT
	DECLARE @doc_type_id TINYINT = 1	
	DECLARE @supplier_id INT
	DECLARE @suppliercontract_id INT
	DECLARE @refund_create_status TINYINT = 1
	
	DECLARE @refund_output TABLE (rmr_id INT)	
	DECLARE @suspect_detail TABLE (shks_id INT, qty DECIMAL(9, 3), okei_id INT)
	
	DECLARE @shk_detail TABLE (
	        	shkrm_id INT NOT NULL,
	        	rmid_id INT NULL,
	        	rmt_id INT NOT NULL,
	        	art_id INT NOT NULL,
	        	color_id INT NOT NULL,
	        	stor_unit_residues_okei_id INT NOT NULL,
	        	stor_unit_residues_qty DECIMAL(9, 3) NOT NULL,
	        	frame_width SMALLINT NULL,
	        	okei_id INT NOT NULL,
	        	qty DECIMAL(9, 3) NOT NULL
	        )
	
	SELECT	@error_text = CASE 
	      	                   WHEN su.shksu_id IS NULL THEN 'Некорректный ШК ' + CAST(v.shksu_id AS VARCHAR(10))
	      	                   WHEN su.doc_id IS NULL THEN 'ШК ' + CAST(v.shksu_id AS VARCHAR(10)) + ' не привязан к документу.'
	      	                   WHEN su.close_dt IS NOT NULL THEN 'ШК ' + CAST(v.shksu_id AS VARCHAR(10)) + ' уже закрыт.'
	      	                   ELSE NULL
	      	              END,
			@doc_id                  = su.doc_id,
			@supplier_id             = rmi.supplier_id,
			@suppliercontract_id     = rmi.suppliercontract_id
	FROM	(VALUES(@shksu_id))v(shksu_id)   
			LEFT JOIN	Warehouse.SHKSpaceUnit su   
			INNER JOIN	Material.RawMaterialIncome rmi
				ON	rmi.doc_id = su.doc_id
				AND	rmi.doc_type_id = su.doc_type_id
				ON	su.shksu_id = v.shksu_id
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Warehouse.SHKSpaceUnit su
	   	WHERE	shksu_id <> @shksu_id
	   			AND	su.doc_id = @doc_id
	   			AND	su.doc_type_id = @doc_type_id
	   			AND	su.close_dt IS NULL
	   )
	BEGIN
	    INSERT @suspect_detail
	      (
	        shks_id,
	        qty,
	        okei_id
	      )
	    SELECT	ssu.shks_id,
	    		ssu.qty,
	    		ssu.okei_id
	    FROM	Warehouse.SHKSpaceUnit su   
	    		INNER JOIN	Warehouse.SHKSuspectUnit ssu
	    			ON	ssu.shksu_id = su.shksu_id
	    WHERE	su.doc_id = @doc_id
	    		AND	su.doc_type_id = @doc_type_id
	    		AND	NOT EXISTS (
	    		   		SELECT	1
	    		   		FROM	Suppliers.RawMaterialRefundSuspectDetail rmrsd
	    		   		WHERE	rmrsd.shks_id = ssu.shks_id
	    		   	) 
	    
	    INSERT @shk_detail
	      (
	        shkrm_id,
	        rmid_id,
	        rmt_id,
	        art_id,
	        color_id,
	        stor_unit_residues_okei_id,
	        stor_unit_residues_qty,
	        frame_width,
	        okei_id,
	        qty
	      )
	    SELECT	smai.shkrm_id,
	    		rmid.rmid_id,
	    		smai.rmt_id,
	    		smai.art_id,
	    		smai.color_id,
	    		smai.stor_unit_residues_okei_id,
	    		smai.stor_unit_residues_qty,
	    		smai.frame_width,
	    		srmdd.okei_id,
	    		srmdd.qty
	    FROM	Warehouse.SHKRawMaterialActualInfo smai   
	    		INNER JOIN	Warehouse.SHKRawMaterialDefectDescr srmdd
	    			ON	srmdd.shkrm_id = smai.shkrm_id   
	    		LEFT JOIN	Material.RawMaterialIncomeDetail rmid
	    			ON	rmid.doc_id = smai.doc_id
	    			AND	rmid.doc_type_id = @doc_type_id
	    			AND	rmid.shkrm_id = smai.shkrm_id
	    WHERE	smai.doc_id = @doc_id
	    		AND	smai.doc_type_id = @doc_type_id
	    		AND	smai.is_defected = 1
	    		AND	NOT EXISTS (
	    		   		SELECT	1
	    		   		FROM	Suppliers.RawMaterialRefundShkDetail rmrsd
	    		   		WHERE	rmrsd.shkrm_id = smai.shkrm_id
	    		   	)
	END
	
	BEGIN TRY
		BEGIN TRANSACTION 
		
		UPDATE	Warehouse.SHKSpaceUnit
		SET 	close_dt = @dt,
				close_employee_id = @employee_id
		WHERE	shksu_id = @shksu_id
				AND	close_dt IS NULL
		
		IF @@ROWCOUNT = 0
		BEGIN
		    SET @with_log = 0
		    RAISERROR('Кто-то до вас успел закрыть это грузовое место', 16, 1)
		    RETURN
		END
		
		IF NOT EXISTS (
		   	SELECT	1
		   	FROM	Warehouse.SHKSpaceUnit su
		   	WHERE	su.doc_id = @doc_id
		   			AND	su.doc_type_id = @doc_type_id
		   			AND	su.close_dt IS NULL
		   )
		BEGIN
		    UPDATE	Material.RawMaterialIncome
		    SET 	rmis_id = @rmi_status_end_income,
		    		dt = @dt,
		    		employee_id = @employee_id
		    		OUTPUT	INSERTED.doc_id,
		    				INSERTED.doc_type_id,
		    				INSERTED.rmis_id,
		    				INSERTED.dt,
		    				INSERTED.employee_id,
		    				INSERTED.supplier_id,
		    				INSERTED.suppliercontract_id,
		    				INSERTED.supply_dt,
		    				INSERTED.is_deleted,
		    				INSERTED.goods_dt,
		    				INSERTED.comment,
		    				INSERTED.payment_comment,
		    				INSERTED.plan_sum,
		    				INSERTED.scan_load_dt
		    		INTO	History.RawMaterialIncome (
		    				doc_id,
		    				doc_type_id,
		    				rmis_id,
		    				dt,
		    				employee_id,
		    				supplier_id,
		    				suppliercontract_id,
		    				supply_dt,
		    				is_deleted,
		    				goods_dt,
		    				comment,
		    				payment_comment,
		    				plan_sum,
		    				scan_load_dt
		    			)
		    WHERE	doc_id = @doc_id
		    		AND	doc_type_id = @doc_type_id
		    		AND	rmis_id = @rmi_status_accept
		    
		    INSERT Suppliers.RawMaterialRefund
		      (
		        supplier_id,
		        suppliercontract_id,
		        rmrs_id,
		        is_deleted,
		        create_dt,
		        create_employee_id,
		        dt,
		        employee_id,
		        comment
		      )OUTPUT	INSERTED.rmr_id
		       INTO	@refund_output (
		       		rmr_id
		       	)
		    VALUES
		      (
		        @supplier_id,
		        @suppliercontract_id,
		        @refund_create_status,
		        0,
		        @dt,
		        @employee_id,
		        @dt,
		        @employee_id,
		        'создан автоматически после полной приемки поступления № ' + CAST(@doc_id AS VARCHAR(10))
		      )
		    
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
		    SELECT	ro.rmr_id,
		    		sd.shks_id,
		    		sd.qty,
		    		sd.okei_id,
		    		0                is_deleted,
		    		@dt              dt,
		    		@employee_id     employee_id
		    FROM	@suspect_detail sd   
		    		CROSS JOIN	@refund_output ro		    		
		    
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
		    SELECT	ro.rmr_id,
		    		sd.rmid_id,
		    		sd.shkrm_id,
		    		sd.rmt_id,
		    		sd.art_id,
		    		sd.color_id,
		    		sd.qty           qty,
		    		sd.okei_id       okei_id,
		    		sd.stor_unit_residues_okei_id,
		    		sd.stor_unit_residues_qty,
		    		sd.frame_width,
		    		0                is_deleted,
		    		@dt              dt,
		    		@employee_id     employee_id
		    FROM	@shk_detail sd   
		    		CROSS JOIN	@refund_output ro
		END 
		
		COMMIT TRANSACTION
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
		
		IF @with_log = 1
		BEGIN
		    RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess) 
		    WITH LOG;
		END
		ELSE
		BEGIN
		    RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess)
		END
	END CATCH
GO	