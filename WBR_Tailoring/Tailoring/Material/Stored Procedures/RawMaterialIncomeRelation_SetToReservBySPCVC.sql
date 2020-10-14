CREATE PROCEDURE [Material].[RawMaterialIncomeRelation_SetToReservBySPCVC]
	@rmodr_id INT,
	@order_reserv_xml XML,
	@employee_id INT,
	@operation_num INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @doc_type_id TINYINT = 1
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)	        
	DECLARE @spcvc_id INT
	DECLARE @sp_id INT
	DECLARE @rmo_id INT
	DECLARE @cvc_state_covered_wh TINYINT = 3	
	DECLARE @rmods_id TINYINT = 3
	DECLARE @proc_id INT	
	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID	
	DECLARE @quantity DECIMAL(12, 2)
	DECLARE @per DECIMAL(5, 2) = 65
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
	
	DECLARE @cv_status_create TINYINT = 1 --Создан
	DECLARE @cv_status_ready TINYINT = 2 --Цветовариант готов к отшиву
	DECLARE @status_complite TINYINT = 4
	DECLARE @status_doc_relation_close_id INT = 7	
	
	
	DECLARE @income_output TABLE (doc_id INT, rv_bigint VARCHAR(20))                	
	
	DECLARE @tab_order_reserv TABLE 
	        (doc_id INT, rv_bigint BIGINT, shkrm_id INT, rmid_id INT, okei_id INT, quantity DECIMAL(12, 3))  
	
	DECLARE @tab_doc TABLE (doc_id INT, rv_bigint BIGINT, rmis_id INT)        	
	
	INSERT @tab_order_reserv
		(
			doc_id,
			rv_bigint,
			shkrm_id,
			rmid_id,
			okei_id,
			quantity
		)
	SELECT	ml.value('@doc_id', 'INT')       doc_id,
			CAST(ml.value('@rv', 'varchar(20)')AS BIGINT) rv,
			ml.value('@shkrm_id', 'INT')     shkrm_id,
			ml.value('@rmid_id', 'INT')      rmid_id,
			ml.value('@okei_id', 'INT')      okei_id,
			ml.value('@qty', 'DECIMAL(12,3)') quantity
	FROM	@order_reserv_xml.nodes('root/det')x(ml)	
	
	INSERT INTO @tab_doc
		(
			doc_id,
			rv_bigint,
			rmis_id
		)
	SELECT	DISTINCT tor.doc_id,
			tor.rv_bigint,
			rmi.rmis_id
	FROM	@tab_order_reserv tor   
			LEFT JOIN	Material.RawMaterialIncome rmi
				ON	rmi.doc_id = tor.doc_id
				AND	rmi.doc_type_id = @doc_type_id
	
	SELECT	@quantity = SUM(tor.quantity)
	FROM	@tab_order_reserv tor 
	
	SELECT	@error_text = CASE 
	      	                   WHEN CAST(rm_inc.rv AS BIGINT) != v.rv_bigint THEN 'Документ №' + CAST(v.doc_id AS VARCHAR(10)) +
	      	                        ' уже кто-то поменял. Перечитайте данные и попробуйте снова.'
	      	                   WHEN rm_inc.doc_id IS NULL THEN 'Поступления материалов с кодом ' + CAST(v.doc_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN rm_inc.is_deleted = 1 THEN 'Поступление материалов удалено'
	      	                   WHEN rm_inc.rmis_id NOT IN (1, 2, 3, 4, 5, 6, 7) THEN 'Статус документа №' + CAST(v.doc_id AS VARCHAR(10)) + ' - "' + rmis.rmis_name 
	      	                        + '" не позволяет распределения'
	      	              END
	FROM	@tab_doc v   
			LEFT JOIN	Material.RawMaterialIncome rm_inc
				ON	rm_inc.doc_id = v.doc_id
				AND	rm_inc.doc_type_id = @doc_type_id   
			INNER JOIN	Material.RawMaterialIncomeStatus rmis
				ON	rmis.rmis_id = rm_inc.rmis_id
	WHERE	CAST(rm_inc.rv AS BIGINT) != v.rv_bigint
			OR	rm_inc.doc_id IS NULL
			OR	rm_inc.is_deleted = 1
			OR	rm_inc.rmis_id NOT IN (1, 2, 3, 4, 5, 6)
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('(%s)', 16, 1, @error_text)
	    RETURN
	END 
	
	
	SELECT	@error_text = CASE 
	      	                   WHEN rmodfr.rmodr_id IS NULL THEN 'Строчки заказа поставщику с кодом ' + CAST(v.rmodr_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN rmodfr.rmods_id = 2 THEN 'Статус детали "' + rmods.rmods_name + '", недоступен для резервирования.'
	      	                   WHEN spcvc.cs_id = @cvc_state_covered_wh THEN 'У текущей позиции уже статус - Закрыт складским остатком'
	      	                   ELSE NULL
	      	              END,
			@spcvc_id     = rmsr.spcvc_id,
			@sp_id        = spcv.sp_id,
			@rmo_id       = rmodfr.rmo_id
	FROM	(VALUES(@rmodr_id))v(rmodr_id)   
			LEFT JOIN	Suppliers.RawMaterialOrderDetailFromReserv rmodfr   
			INNER JOIN	Suppliers.RawMaterialOrderDetailStatus rmods
				ON	rmods.rmods_id = rmodfr.rmods_id   
			INNER JOIN	Suppliers.RawMaterialStockReserv rmsr
				ON	rmsr.rmsr_id = rmodfr.rmsr_id   
			INNER JOIN	Planing.SketchPlanColorVariantCompleting spcvc
				ON	spcvc.spcvc_id = rmsr.spcvc_id   
			INNER JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.spcv_id = spcvc.spcv_id
				ON	rmodfr.rmodr_id = v.rmodr_id
	
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	IF EXISTS(
	   	SELECT	1
	   	FROM	Warehouse.SHKRawMaterialReserv smr
	   	WHERE	smr.spcvc_id = @spcvc_id
	   )
	BEGIN
	    RAISERROR('По этой позиции уже есть резерв', 16, 1)
	    RETURN
	END
	
	IF EXISTS(
	   	SELECT	1
	   	FROM	Material.RawMaterialIncomeOrderReservRelationDetail rmiorrd
	   	WHERE	rmiorrd.rmodr_id = @rmodr_id
	   )
	BEGIN
	    RAISERROR('По этой позиции уже есть распределение резерва', 16, 1)
	    RETURN
	END
	
	
	
	SELECT	@error_text = CASE 
	      	                   WHEN rmid.rmid_id IS NULL THEN 'Не найдена деталь табличной части поступления для шк ' + CAST(td.shkrm_id AS VARCHAR(10))
	      	                   WHEN rmid.stor_unit_residues_qty -(ISNULL(oa_orrd.qty, 0) + ISNULL(oa_ord.qty, 0)) - td.quantity - oa_res.reserv_qty < 0 THEN 'По ШК ' + CAST(td.shkrm_id AS VARCHAR(10)) 
	      	                        + ' не хватает остатка.'
	      	                   ELSE NULL
	      	              END
	FROM	@tab_order_reserv td   
			LEFT JOIN	Material.RawMaterialIncomeDetail rmid
				ON	rmid.rmid_id = td.rmid_id
				AND	rmid.doc_id = td.doc_id
				AND	rmid.doc_type_id = @doc_type_id   
			OUTER APPLY (
			      	SELECT	SUM(rmiorrd.quantity) qty
			      	FROM	Material.RawMaterialIncomeOrderReservRelationDetail rmiorrd
			      	WHERE	rmiorrd.rmid_id = rmid.rmid_id
			      			AND	rmiorrd.doc_id = rmid.doc_id
			      			AND	rmiorrd.doc_type_id = rmid.doc_type_id
			      ) oa_orrd
			OUTER APPLY (
	      			SELECT	SUM(rmiord.quantity) qty
	      			FROM	Material.RawMaterialIncomeOrderRelationDetail rmiord
	      			WHERE	rmiord.rmid_id = rmid.rmid_id
	      					AND	rmiord.doc_id = rmid.doc_id
	      					AND	rmiord.doc_type_id = rmid.doc_type_id
				  ) oa_ord
	      OUTER APPLY (
	            	SELECT	SUM(smr.quantity) reserv_qty
	            	FROM	Warehouse.SHKRawMaterialReserv smr
	            	WHERE	smr.shkrm_id = td.shkrm_id
	            ) oa_res
	WHERE	rmid.rmid_id IS NULL
			OR	rmid.stor_unit_residues_qty -(ISNULL(oa_orrd.qty, 0) + ISNULL(oa_ord.qty, 0)) - td.quantity - oa_res.reserv_qty < 0
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s.', 16, 1, @error_text)
	    RETURN
	END 		
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		UPDATE	rmi
		SET 	employee_id = @employee_id,
				dt = @dt
				OUTPUT	INSERTED.doc_id,
						CAST(CAST(INSERTED.rv AS BIGINT) AS VARCHAR(20))
				INTO	@income_output (
						doc_id,
						rv_bigint
					)
		FROM	Material.RawMaterialIncome rmi
				INNER JOIN	@tab_doc td
					ON	td.doc_id = rmi.doc_id
					AND	rmi.doc_type_id = @doc_type_id
					AND	CAST(rmi.rv AS BIGINT) = td.rv_bigint
		
		IF (
		   	SELECT	COUNT(*)
		   	FROM	@income_output
		   ) != (
		   	SELECT	COUNT(*)
		   	FROM	@tab_doc
		   )
		BEGIN
		    RAISERROR('Обновите данные и попробуйте снова', 16, 1)
		    RETURN
		END
		
		INSERT INTO Material.RawMaterialIncomeOrder
			(
				doc_id,
				doc_type_id,
				rmo_id,
				employee_id,
				dt
			)
		SELECT	td.doc_id,
				@doc_type_id,
				@rmo_id,
				@employee_id,
				@dt
		FROM	@tab_doc td
		WHERE	NOT EXISTS (
		     		SELECT	1
		     		FROM	Material.RawMaterialIncomeOrder rmio
		     		WHERE	rmio.doc_id = td.doc_id
		     				AND	rmio.doc_type_id = @doc_type_id
		     				AND	rmio.rmo_id = @rmo_id
		     	)
		
		INSERT Material.RawMaterialIncomeOrderReservRelationDetail
			(
				rmid_id,
				rmodr_id,
				spcvc_id,
				okei_id,
				quantity,
				doc_id,
				doc_type_id,
				operation_num
			)
		SELECT	rmid_id,
				@rmodr_id,
				@spcvc_id,
				okei_id,
				quantity,
				doc_id,
				@doc_type_id          doc_type_id,
				@operation_num
		FROM	@tab_order_reserv     tor
		
		
		INSERT INTO Warehouse.SHKRawMaterialReserv
			(
				shkrm_id,
				spcvc_id,
				okei_id,
				quantity,
				dt,
				employee_id,
				rmid_id,
				rmodr_id
			)OUTPUT	INSERTED.shkrm_id,
			 		INSERTED.spcvc_id,
			 		INSERTED.okei_id,
			 		INSERTED.quantity,
			 		@dt,
			 		@employee_id,
			 		INSERTED.rmid_id,
			 		INSERTED.rmodr_id,
			 		@proc_id,
			 		'I'
			 INTO	History.SHKRawMaterialReserv (
			 		shkrm_id,
			 		spcvc_id,
			 		okei_id,
			 		quantity,
			 		dt,
			 		employee_id,
			 		rmid_id,
			 		rmodr_id,
			 		proc_id,
			 		operation
			 	)
		SELECT	tor.shkrm_id,
				@spcvc_id,
				tor.okei_id,
				tor.quantity,
				@dt,
				@employee_id,
				tor.rmid_id,
				@rmodr_id
		FROM	@tab_order_reserv tor
		WHERE	NOT EXISTS(
		     		SELECT	1
		     		FROM	Warehouse.SHKRawMaterialReserv smr
		     		WHERE	smr.spcvc_id = @spcvc_id
		     	)
		
		IF @@ROWCOUNT = 0
		BEGIN
		    RAISERROR('По этой позиции уже есть резерв', 16, 1)
		    RETURN
		END
		
		IF EXISTS (
		   	SELECT	1
		   	FROM	Warehouse.SHKRawMaterialActualInfo smai
		   	WHERE	EXISTS(
		   	     		SELECT	1
		   	     		FROM	@tab_order_reserv tor
		   	     		WHERE	tor.shkrm_id = smai.shkrm_id
		   	     	)
		   			AND	EXISTS (
		   			   		SELECT	1
		   			   		FROM	Warehouse.SHKRawMaterialReserv smr
		   			   		WHERE	smr.shkrm_id = smai.shkrm_id
		   			   		HAVING
		   			   			SUM(smr.quantity) > smai.stor_unit_residues_qty
		   			   	)
		)
		BEGIN
		    RAISERROR('Возникло превышение резервов, обновите данные и попробуйте ещё раз', 16, 1)
		    RETURN
		END
		
		IF EXISTS(
		   	SELECT	1
		   	FROM	@tab_doc td
		   	WHERE	td.rmis_id = @status_doc_relation_close_id
		   )
		BEGIN
		    UPDATE	rmodr
		    SET 	rmods_id = @rmods_id
		    FROM	Suppliers.RawMaterialOrderDetailFromReserv rmodr
		    WHERE	rmodr.rmodr_id = @rmodr_id
		    		AND	rmodr.rmods_id != @rmods_id
		    		AND	CASE 
		    		   	     WHEN rmodr.qty <= @quantity THEN 1
		    		   	     WHEN 100 * @quantity / rmodr.qty >= @per THEN 1
		    		   	     ELSE 0
		    		   	END = 1 
		    
		    UPDATE	spcvc
		    SET 	cs_id = @cvc_state_covered_wh,
		    		employee_id = @employee_id,
		    		dt = @dt
		    		OUTPUT	
		    			INSERTED.spcvc_id,
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
		    FROM	Planing.SketchPlanColorVariantCompleting spcvc
		    		INNER JOIN	Planing.SketchPlanColorVariant spcv
		    			ON	spcv.spcv_id = spcvc.spcv_id
		    WHERE	spcvc.spcvc_id = @spcvc_id
		    		AND	CASE 
		    		   	     WHEN spcvc.consumption * spcv.qty <= @quantity THEN 1
		    		   	     WHEN (100 * @quantity) / (spcvc.consumption * spcv.qty) >= @per THEN 1
		    		   	     ELSE 0
		    		   	END = 1 
		    
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
		
		RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess) 
		WITH LOG;
	END CATCH
GO