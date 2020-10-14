CREATE PROCEDURE [Material].[RawMaterialIncome_RelationClose_v3]
	@doc_id INT,
	@employee_id INT,
	@rv_bigint VARCHAR(20)
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE(),
	        @doc_type_id TINYINT = 1,
	        @status_doc_relation_close_id INT = 7,
	        @error_text VARCHAR(MAX),
	        @rv ROWVERSION = CAST(CAST(@rv_bigint AS BIGINT) AS ROWVERSION),
	        @rmods_id TINYINT = 3,
	        @per DECIMAL(5, 2) = 65,
	        @currency_id INT,
	        @rub_currency_id INT = 1,
	        @ots_id INT
	
	DECLARE @need_sync_vas BIT
	DECLARE @cvc_state_covered_wh TINYINT = 3
	DECLARE @cv_status_create TINYINT = 1 --Создан
	DECLARE @cv_status_ready TINYINT = 2 --Цветовариант готов к отшиву	 
	DECLARE @status_complite TINYINT = 4
	DECLARE @reserv TABLE (spcvc_id INT, quantity DECIMAL(9, 3), rmodr_id INT)
	DECLARE @raw_material_order_detail_from_feserv_output TABLE(rmsr_id INT, rmodr_id INT)
	DECLARE @sketch_plan_color_variant_completing_output TABLE(
	        	spcvc_id INT NOT NULL,
	        	spcv_id INT NOT NULL,
	        	completing_id INT NOT NULL,
	        	completing_number TINYINT NOT NULL,
	        	rmt_id INT NOT NULL,
	        	color_id INT NOT NULL,
	        	frame_width SMALLINT NULL,
	        	okei_id INT NOT NULL,
	        	consumption DECIMAL(9, 3) NULL,
	        	comment VARCHAR(300) NULL,
	        	dt dbo.SECONDSTIME NOT NULL,
	        	employee_id INT NOT NULL,
	        	cs_id TINYINT
	        )
	
	DECLARE @sketch_plan_color_variant_output TABLE(
	        	spcv_id INT NOT NULL,
	        	sp_id INT NOT NULL,
	        	spcv_name VARCHAR(36) NOT NULL,
	        	cvs_id TINYINT NOT NULL,
	        	qty SMALLINT NOT NULL,
	        	employee_id INT NOT NULL,
	        	dt dbo.SECONDSTIME NOT NULL,
	        	is_deleted BIT NOT NULL,
	        	comment VARCHAR(300) NULL,
	        	pan_id INT NULL,
	        	corrected_qty SMALLINT NULL,
	        	begin_plan_delivery_dt DATE NULL,
	        	end_plan_delivery_dt DATE NULL,
	        	sew_office_id INT NULL,
	        	sew_deadline_dt DATE NULL,
	        	cost_plan_year SMALLINT NULL,
	        	cost_plan_month TINYINT NULL
	        )
	
	DECLARE @proc_id INT
	
	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID
	
	DECLARE @suppliercontract_code VARCHAR(9)
	DECLARE @supplier_id INT 
	DECLARE @office_id INT 

	
	DECLARE @doc_dt DATETIME2(0)
		
	SELECT	@office_id = os.office_id
	FROM	Settings.OfficeSetting os
	WHERE	os.is_main_wh = 1
	
	SELECT	@error_text = CASE 
	      	                   WHEN rmi.doc_id IS NULL THEN 'Поступления материалов с кодом ' + CAST(v.doc_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN rmi.is_deleted = 1 THEN 'Поступление материалов удалено'
	      	                   WHEN rmi.rv != @rv THEN 'Документ уже кто-то поменял. Перечитайте данные и попробуйте записать снова.'
	      	                   WHEN rmisg.rmis_src_id IS NULL THEN 'Запрещен переход в статус ' + rmisd.rmis_name + ' из текущего статуса ' + rmis.rmis_name
	      	                   WHEN inv2.rmi_id IS NULL THEN 'Не подлита первичка, закрывать нельзя'
	      	                   WHEN ex.rmie_id IS NOT NULL THEN 'У поступления не распределили доп. затрату № ' + CAST(ex.rmie_id AS VARCHAR(10))
	      	                   WHEN inv.invoice_name IS NOT NULL THEN 'У поступления не распределили у СФ ' + CAST(inv.invoice_name AS VARCHAR(10)) +
	      	                        ' позицию № ' + CAST(inv.item_number AS VARCHAR(10)) + '(сумма позиции: ' + CAST(inv.amount_with_nds AS VARCHAR(20)) +
	      	                        ', сумма распределения: ' + CAST(inv.rel_amount AS VARCHAR(20)) + ')'
	      	                        --WHEN res.is_not_reserv IS NOT NULL THEN 'У поступления не проводилось распределение резервов'
	      	                   WHEN det_no_rd.rmid_id IS NOT NULL THEN 'В поступлении есть ШК без распределения стоимости, закрывать нельзя'
	      	                   WHEN det_return_rd.rmid_id IS NOT NULL THEN 'В поступлении есть возвратные ШК с распределеной стоимостью, закрывать нельзя'
	      	                   WHEN rmi.doc_id IS NOT NULL AND NOT EXISTS (
	      	                        	SELECT	1
	      	                        	FROM	Material.RawMaterialInvoice rmi2
	      	                        	WHERE	rmi2.doc_id = v.doc_id
	      	                        			AND	rmi2.doc_type_id = v.doc_type_id
	      	                        ) THEN 'Для поступления материалов с кодом ' + CAST(v.doc_id AS VARCHAR(10)) + ' нет счетфактуры.'
	      	                        --WHEN oa_ots.rmid_id IS NOT NULL THEN 'В поступлении есть позиции, которых нет в заказе'
	      	              END,
			@suppliercontract_code = sc.suppliercontract_code,
			@supplier_id = sc.supplier_id,
			@doc_dt = rmi.supply_dt,
			@currency_id = sc.currency_id,
			@ots_id = rmi.ots_id,
			@need_sync_vas = CASE 
			                      WHEN s.supplier_source_id = 2 THEN 1
			                      ELSE 0
			                 END
	FROM	(VALUES(@doc_id,
			@doc_type_id))v(doc_id,
			doc_type_id)   
			LEFT JOIN	Material.RawMaterialIncome rmi   
			INNER JOIN	Suppliers.SupplierContract sc   
			INNER JOIN	Suppliers.Supplier s
				ON	s.supplier_id = sc.supplier_id
				ON	sc.suppliercontract_id = rmi.suppliercontract_id   
			INNER JOIN	Material.RawMaterialIncomeStatus rmis
				ON	rmis.rmis_id = rmi.rmis_id   
			LEFT JOIN	Material.RawMaterialIncomeStatusGraph rmisg
				ON	rmisg.rmis_src_id = rmi.rmis_id
				AND	rmisg.rmis_dst_id = @status_doc_relation_close_id
				ON	rmi.doc_id = v.doc_id
				AND	rmi.doc_type_id = v.doc_type_id   
			LEFT JOIN	Material.RawMaterialIncomeStatus rmisd
				ON	rmisd.rmis_id = @status_doc_relation_close_id   
			OUTER APPLY (
			      	SELECT	TOP(1) rmie.rmie_id,
			      			rmie.amount,
			      			ISNULL(SUM(rmierd.amount), 0) rel_amount
			      	FROM	Material.RawMaterialIncomeExpense rmie   
			      			LEFT JOIN	Material.RawMaterialIncomeExpenseRelationDetail rmierd
			      				ON	rmierd.rmie_id = rmie.rmie_id
			      	WHERE	rmie.doc_id = v.doc_id
			      			AND	rmie.doc_type_id = v.doc_type_id
			      	GROUP BY
			      		rmie.rmie_id,
			      		rmie.amount
			      	HAVING
			      		rmie.amount <> ISNULL(SUM(rmierd.amount), 0)
			      ) ex
	OUTER APPLY (
	      	SELECT	TOP(1) rm_inv.invoice_name,
	      			rmid.item_number,
	      			rmid.amount_with_nds,
	      			ISNULL(SUM(rmird.amount), 0) rel_amount
	      	FROM	Material.RawMaterialInvoice rm_inv   
	      			INNER JOIN	Material.RawMaterialInvoiceDetail rmid
	      				ON	rmid.rmi_id = rm_inv.rmi_id   
	      			LEFT JOIN	Material.RawMaterialInvoiceRelationDetail rmird
	      				ON	rmird.rm_invd_id = rmid.rmid_id
	      	WHERE	rm_inv.doc_id = v.doc_id
	      			AND	rm_inv.doc_type_id = v.doc_type_id
	      	GROUP BY
	      		rm_inv.invoice_name,
	      		rmid.item_number,
	      		rmid.amount_with_nds
	      	HAVING
	      		rmid.amount_with_nds <> ISNULL(SUM(rmird.amount), 0)
	      ) inv 
	OUTER APPLY (
	      	SELECT	TOP(1) 
	      	      	1 is_not_reserv
	      	FROM	Material.RawMaterialIncomeDetail rmid   
	      			LEFT JOIN	Material.RawMaterialIncomeOrderRelationDetail rmiord
	      				ON	rmiord.rmid_id = rmid.rmid_id   
	      			LEFT JOIN	Material.RawMaterialIncomeOrderReservRelationDetail rmiorrd
	      				ON	rmiorrd.rmid_id = rmid.rmid_id
	      	WHERE	rmiord.rmid_id IS NULL
	      			AND	rmiorrd.rmid_id IS NULL
	      			AND	rmid.doc_id = v.doc_id
	      			AND	rmid.doc_type_id = v.doc_type_id
	      ) res 
	OUTER APPLY (
	      	SELECT	TOP(1) rmid.rmid_id
	      	FROM	Material.RawMaterialIncomeDetail rmid   
	      			LEFT JOIN	Material.RawMaterialInvoiceRelationDetail rmird
	      				ON	rmird.rmid_id = rmid.rmid_id   
	      			LEFT JOIN	Material.RawMaterialReturn rmr
	      				ON	rmr.doc_id = rmid.doc_id
	      				AND	rmr.doc_type_id = rmid.doc_type_id
	      				AND	rmr.rmid_id = rmid.rmid_id
	      	WHERE	rmid.doc_id = v.doc_id
	      			AND	rmid.doc_type_id = v.doc_type_id
	      			AND	rmird.rmid_id IS NULL
	      			AND	rmr.rmid_id IS NULL
	      ) det_no_rd
	OUTER APPLY (
	      	SELECT	TOP(1) rmid.rmid_id
	      	FROM	Material.RawMaterialIncomeDetail rmid   
	      			INNER JOIN	Material.RawMaterialInvoiceRelationDetail rmird
	      				ON	rmird.rmid_id = rmid.rmid_id   
	      			INNER JOIN	Material.RawMaterialReturn rmr
	      				ON	rmr.doc_id = rmid.doc_id
	      				AND	rmr.doc_type_id = rmid.doc_type_id
	      				AND	rmr.rmid_id = rmid.rmid_id
	      	WHERE	rmid.doc_id = v.doc_id
	      			AND	rmid.doc_type_id = v.doc_type_id
	      ) det_return_rd 
	OUTER APPLY (
	      	SELECT	TOP(1) rm_inv2.rmi_id
	      	FROM	Material.RawMaterialInvoice rm_inv2
	      	WHERE	rm_inv2.doc_id = v.doc_id
	      			AND	rm_inv2.doc_type_id = v.doc_type_id
	      			AND	rm_inv2.is_deleted = 0
	      ) inv2 

	
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END		
	
	IF @currency_id IS NULL
	BEGIN
	    RAISERROR('В договоре не проставлена валюта', 16, 1)
	    RETURN
	END
	
	IF @currency_id != @rub_currency_id
	   AND EXISTS(
	       	SELECT	1
	       	FROM	Material.RawMaterialInvoiceDetail rmid   
	       			INNER  JOIN	Material.RawMaterialInvoice rmi
	       				ON	rmi.rmi_id = rmid.rmi_id
	       	WHERE	rmi.doc_id = @doc_id
	       			AND	rmi.doc_type_id = @doc_type_id
	       			AND	ISNULL(rmid.amount_cur_with_nds, 0) = 0
	       			AND	rmi.is_deleted = 0
	       )
	BEGIN
	    RAISERROR('Не заполнены валютные суммы', 16, 1)
	    RETURN
	END
	
	IF EXISTS(
	   	SELECT	1
	   	FROM	Material.RawMaterialInvoice rmi
	   	WHERE	rmi.set_file_dt IS NULL
	   			AND	rmi.doc_id = @doc_id
	   			AND	rmi.doc_type_id = @doc_type_id
	   			AND	rmi.is_deleted = 0
	   			AND	NOT EXISTS (
	   			   		SELECT	1
	   			   		FROM	Synchro.DownloadUPD_Mapping dum
	   			   		WHERE	dum.rmi_id = rmi.rmi_id
	   			   	)
	   )
	BEGIN
	    RAISERROR('Не подгружены сканы', 16, 1)
	    RETURN
	END
	
	INSERT INTO @reserv
		(
			spcvc_id,
			quantity,
			rmodr_id
		)
	SELECT	smr.spcvc_id,
			SUM(smr.quantity) quantity,
			rmiorrd.rmodr_id
	FROM	Warehouse.SHKRawMaterialReserv smr   
			INNER JOIN	Material.RawMaterialIncomeOrderReservRelationDetail rmiorrd
				ON	rmiorrd.spcvc_id = smr.spcvc_id
	WHERE	rmiorrd.doc_id = @doc_id
			AND	rmiorrd.doc_type_id = @doc_type_id
	GROUP BY
		smr.spcvc_id,
		rmiorrd.rmodr_id
	
	
	BEGIN TRY
		BEGIN TRANSACTION 	
		
		UPDATE	rmi
		SET 	rmis_id = @status_doc_relation_close_id,
				dt = @dt,
				employee_id = @employee_id,
				reserv_close_dt = @dt
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
		FROM	Material.RawMaterialIncome rmi
				INNER JOIN	Material.RawMaterialIncomeStatusGraph rmisg
					ON	rmi.rmis_id = rmisg.rmis_src_id
					AND	rmisg.rmis_dst_id = @status_doc_relation_close_id
		WHERE	rmi.rv = @rv
				AND	rmi.doc_id = @doc_id
				AND	rmi.doc_type_id = @doc_type_id		
		
		IF @@ROWCOUNT = 0
		BEGIN
		    RAISERROR('Не удалось обновить статус, возможно его кто-то уже поменял или документ был уже изменен', 16, 1)
		    RETURN
		END	
		
		UPDATE	sma
		SET 	final_dt = @dt
		FROM	Material.RawMaterialIncomeDetail rmid
				INNER JOIN	Warehouse.SHKRawMaterialAmount sma
					ON	sma.shkrm_id = rmid.shkrm_id
		WHERE	rmid.doc_id = @doc_id
		
		UPDATE	rmodr
		SET 	rmods_id = @rmods_id
		    	OUTPUT	INSERTED.rmsr_id,
		    			INSERTED.rmodr_id
		    	INTO	@raw_material_order_detail_from_feserv_output (
		    			rmsr_id,
		    			rmodr_id
		    		)
		FROM	Suppliers.RawMaterialOrderDetailFromReserv rmodr
				INNER JOIN	@reserv sro
					ON	sro.rmodr_id = rmodr.rmodr_id
		WHERE	CASE 
		     	     WHEN rmodr.qty <= sro.quantity THEN 1
		     	     WHEN 100 * sro.quantity / rmodr.qty >= @per THEN 1
		     	     ELSE 0
		     	END = 1 
		
		UPDATE	spcvc
		SET 	cs_id = @cvc_state_covered_wh,
				employee_id = @employee_id,
				dt = @dt
				OUTPUT	INSERTED.spcvc_id,
						INSERTED.spcv_id,
						INSERTED.completing_id,
						INSERTED.completing_number,
						INSERTED.rmt_id,
						INSERTED.color_id,
						INSERTED.frame_width,
						INSERTED.okei_id,
						INSERTED.consumption,
						INSERTED.comment,
						INSERTED.dt,
						INSERTED.employee_id,
						INSERTED.cs_id
				INTO	@sketch_plan_color_variant_completing_output (
						spcvc_id,
						spcv_id,
						completing_id,
						completing_number,
						rmt_id,
						color_id,
						frame_width,
						okei_id,
						consumption,
						comment,
						dt,
						employee_id,
						cs_id
					)
		FROM	@raw_material_order_detail_from_feserv_output rout
				INNER JOIN	@reserv r
					ON	r.rmodr_id = rout.rmodr_id
				INNER JOIN	Planing.SketchPlanColorVariantCompleting spcvc
					ON	spcvc.spcvc_id = r.spcvc_id
		
		INSERT INTO History.SketchPlanColorVariantCompleting
			(
				spcvc_id,
				spcv_id,
				completing_id,
				completing_number,
				rmt_id,
				color_id,
				frame_width,
				okei_id,
				consumption,
				comment,
				dt,
				employee_id,
				cs_id,
				proc_id
			)
		SELECT	spcvco.spcvc_id,
				spcvco.spcv_id,
				spcvco.completing_id,
				spcvco.completing_number,
				spcvco.rmt_id,
				spcvco.color_id,
				spcvco.frame_width,
				spcvco.okei_id,
				spcvco.consumption,
				spcvco.comment,
				spcvco.dt,
				spcvco.employee_id,
				spcvco.cs_id,
				@proc_id
		FROM	@sketch_plan_color_variant_completing_output spcvco	
		
		UPDATE	spcv
		SET 	cvs_id = @cv_status_ready,
				employee_id = @employee_id,
				dt = @dt
				OUTPUT	INSERTED.spcv_id,
						INSERTED.sp_id,
						INSERTED.spcv_name,
						INSERTED.cvs_id,
						INSERTED.qty,
						INSERTED.employee_id,
						INSERTED.dt,
						INSERTED.is_deleted,
						INSERTED.comment,
						INSERTED.pan_id,
						INSERTED.corrected_qty,
						INSERTED.begin_plan_delivery_dt,
						INSERTED.end_plan_delivery_dt,
						INSERTED.sew_office_id,
						INSERTED.sew_deadline_dt,
						INSERTED.cost_plan_year,
						INSERTED.cost_plan_month
				INTO	@sketch_plan_color_variant_output (
						spcv_id,
						sp_id,
						spcv_name,
						cvs_id,
						qty,
						employee_id,
						dt,
						is_deleted,
						comment,
						pan_id,
						corrected_qty,
						begin_plan_delivery_dt,
						end_plan_delivery_dt,
						sew_office_id,
						sew_deadline_dt,
						cost_plan_year,
						cost_plan_month
					)
		FROM	Planing.SketchPlanColorVariant spcv
		WHERE	cvs_id = @cv_status_create
				AND	EXISTS (
				   		SELECT	1
				   		FROM	@sketch_plan_color_variant_completing_output spcvo
				   		WHERE	spcvo.spcv_id = spcv.spcv_id
				   	)
				AND	NOT EXISTS (
				   		SELECT	1
				   		FROM	Planing.SketchPlanColorVariantCompleting spcvc
				   		WHERE	spcvc.spcv_id = spcv.spcv_id
				   				AND	spcvc.cs_id != @cvc_state_covered_wh
				   	)	
		
		INSERT INTO History.SketchPlanColorVariant
			(
				spcv_id,
				sp_id,
				spcv_name,
				cvs_id,
				qty,
				employee_id,
				dt,
				is_deleted,
				comment,
				pan_id,
				corrected_qty,
				begin_plan_delivery_dt,
				end_plan_delivery_dt,
				sew_office_id,
				sew_deadline_dt,
				cost_plan_year,
				cost_plan_month,
				proc_id
			)
		SELECT	sot.spcv_id,
				sot.sp_id,
				sot.spcv_name,
				sot.cvs_id,
				sot.qty,
				sot.employee_id,
				sot.dt,
				sot.is_deleted,
				sot.comment,
				sot.pan_id,
				sot.corrected_qty,
				sot.begin_plan_delivery_dt,
				sot.end_plan_delivery_dt,
				sot.sew_office_id,
				sot.sew_deadline_dt,
				sot.cost_plan_year,
				sot.cost_plan_month,
				@proc_id
		FROM	@sketch_plan_color_variant_output sot	
		
		UPDATE	sp
		SET 	ps_id = @status_complite,
				sp.employee_id = @employee_id,
				sp.dt = @dt
				OUTPUT	INSERTED.sp_id,
						INSERTED.sketch_id,
						INSERTED.ps_id,
						INSERTED.employee_id,
						INSERTED.dt,
						INSERTED.comment
				INTO	History.SketchPlan (
						sp_id,
						sketch_id,
						ps_id,
						employee_id,
						dt,
						comment
					)
		FROM	Planing.SketchPlan sp
		WHERE	sp.ps_id != @status_complite
				AND	EXISTS (
				   		SELECT	1
				   		FROM	@sketch_plan_color_variant_output spco
				   		WHERE	spco.sp_id = sp.sp_id
				   	)
				AND	NOT EXISTS (
				   		SELECT	1
				   		FROM	Planing.SketchPlanColorVariant spcv   
				   				INNER JOIN	Planing.SketchPlanColorVariantCompleting spcvc
				   					ON	spcvc.spcv_id = spcv.spcv_id
				   		WHERE	spcv.sp_id = sp.sp_id
				   				AND	spcvc.cs_id NOT IN (@cvc_state_covered_wh)
				   				AND	spcv.is_deleted = 0
				   	) 
		

		IF @need_sync_vas = 1 
		BEGIN
			INSERT INTO Synchro.Upload_RMI_BuhVas
				(
					rm_inv_id,
					dt
				)
			SELECT	rmi.rmi_id,
					@dt
			FROM	Material.RawMaterialInvoice rmi
			WHERE	rmi.doc_id = @doc_id
					AND	rmi.doc_type_id = @doc_type_id
					AND	rmi.is_deleted = 0
		END
		
		COMMIT TRANSACTION
		
		SELECT	CAST(CAST(rmi.rv AS BIGINT) AS VARCHAR(20)) rv_bigint
		FROM	Material.RawMaterialIncome rmi
		WHERE	rmi.doc_id = @doc_id
				AND	rmi.doc_type_id = @doc_type_id
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