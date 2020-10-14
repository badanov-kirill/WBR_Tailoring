CREATE PROCEDURE [Warehouse].[SHKRawMaterial_Reserv]
	@spcvc_id INT,
	@employee_id INT,
	@data_xml XML
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @qty_need DECIMAL(9, 3)
	DECLARE @qty_res DECIMAL(9, 3)
	DECLARE @rmt_id INT
	DECLARE @okei_id INT
	DECLARE @reserv_output TABLE (shkrm_id INT, spcvc_id INT, okei_id INT, quantity DECIMAL(9, 3), rmid_id INT, rmodr_id INT)
	DECLARE @shkrm_id INT
	DECLARE @sp_id INT
	DECLARE @with_log BIT = 1
	DECLARE @proc_id INT	
	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID
	DECLARE @rmod_status_deleted TINYINT = 2 -- удален
	
	DECLARE @cvc_state_need_proc TINYINT = 1
	DECLARE @cvc_state_order_sup TINYINT = 2
	DECLARE @cvc_state_covered_wh TINYINT = 3
	
	DECLARE @cv_status_create TINYINT = 1 --Создан
	DECLARE @cv_status_ready TINYINT = 2 --Цветовариант готов к отшиву
	
	DECLARE @status_processed_bayer TINYINT = 8
	DECLARE @status_complite TINYINT = 4
	
	DECLARE @data_tab TABLE (shkrm_id INT)
	
	SELECT	@error_text = CASE 
	      	                   WHEN spcvc.spcvc_id IS NULL THEN 'Строчки комплектации изделия с кодом ' + CAST(v.spcvc_id AS VARCHAR(10)) + ' не существует.'
	      	                   --WHEN spcvc.cs_id != @cvc_state_need_proc THEN 'Строчка комплектации изделия находится в статусе ' + cs.cs_name +
	      	                   --     ', резервирование со склада запрещено.'
	      	                   --WHEN oar.is_reserv IS NOT NULL THEN 'Строчка комплектации изделия уже имеет резерв.'
	      	                   WHEN spcvc.consumption * spcv.qty <= 0 THEN 'Количество необходимого материала должно быть больше 0.'
	      	                   WHEN spcvc.consumption * spcv.qty <= ISNULL(oar.qty, 0) THEN 'Текущие резервы уже перекрывают потребность'
	      	                   ELSE NULL
	      	              END,
			@qty_need     = spcvc.consumption * spcv.qty - ISNULL(oar.qty, 0),
			@qty_res      = spcvc.consumption * spcv.qty - ISNULL(oar.qty, 0),
			@rmt_id       = spcvc.rmt_id,
			@okei_id      = spcvc.okei_id,
			@sp_id        = spcv.sp_id
	FROM	(VALUES(@spcvc_id))v(spcvc_id)   
			LEFT JOIN	Planing.SketchPlanColorVariantCompleting spcvc   
			INNER JOIN	Planing.CompletingStatus cs
				ON	cs.cs_id = spcvc.cs_id   
			INNER JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.spcv_id = spcvc.spcv_id
				ON	spcvc.spcvc_id = v.spcvc_id   
			OUTER APPLY (
			      	SELECT	SUM(smr.quantity) qty
			      	FROM	Warehouse.SHKRawMaterialReserv smr
			      	WHERE	smr.spcvc_id = v.spcvc_id
			      ) oar
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	INSERT INTO @data_tab
	  (
	    shkrm_id
	  )
	SELECT	ml.value('@shkrm[1]', 'int')
	FROM	@data_xml.nodes('root/det')x(ml)
	
	SELECT	@error_text = CASE 
	      	                   WHEN sm.shkrm_id IS NULL THEN 'ШК ' + CAST(dt.shkrm_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN smai.shkrm_id IS NULL THEN 'ШК ' + CAST(dt.shkrm_id AS VARCHAR(10)) + ' не описан'
	      	                   --WHEN smai.rmt_id != @rmt_id THEN 'В выбранных шк, есть не подходящие по типу материала'
	      	                   WHEN sms.shkrm_id IS NULL THEN 'ШК ' + CAST(dt.shkrm_id AS VARCHAR(10)) + ' не имеет статуса'
	      	                   WHEN sms.state_id NOT IN (3) THEN 'ШК в статусе ' + smsd.state_name + ', резервировать нельзя.'
	      	                   WHEN smai.stor_unit_residues_okei_id != @okei_id THEN 'ШК ' + CAST(dt.shkrm_id AS VARCHAR(10)) +
	      	                        ' имеет еденицу хранения остатков, отличную от потребности'
	      	                   WHEN smr.shkrm_id IS NOT NULL THEN  'ШК ' + CAST(dt.shkrm_id AS VARCHAR(10)) + ' уже использован для резерва на эту комплектацию.'
	      	                   ELSE NULL
	      	              END
	FROM	@data_tab dt   
			LEFT JOIN	Warehouse.SHKRawMaterial sm
				ON	sm.shkrm_id = dt.shkrm_id   
			LEFT JOIN	Warehouse.SHKRawMaterialActualInfo smai
				ON	smai.shkrm_id = sm.shkrm_id   
			LEFT JOIN	Warehouse.SHKRawMaterialState sms   
			INNER JOIN	Warehouse.SHKRawMaterialStateDict smsd
				ON	smsd.state_id = sms.state_id
				ON	sms.shkrm_id = sm.shkrm_id
			LEFT JOIN Warehouse.SHKRawMaterialReserv smr
				ON smr.shkrm_id = smai.shkrm_id AND smr.spcvc_id = @spcvc_id
	WHERE	sm.shkrm_id IS NULL
			OR	smai.shkrm_id IS NULL
			--OR	smai.rmt_id != @rmt_id
			OR	sms.shkrm_id IS NULL
			OR	sms.state_id NOT IN (3)
			OR	smai.stor_unit_residues_okei_id != @okei_id
			OR	smr.shkrm_id IS NOT NULL
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN SUM(smai.stor_unit_residues_qty) <= SUM(oa.qty) THEN 'Выбранные ШК не имеют свободного остатка'
	      	                   WHEN @qty_need > SUM(smai.stor_unit_residues_qty) THEN 'Остатка по выбранным ШК ' + CAST(SUM(smai.stor_unit_residues_qty) AS VARCHAR(10)) +
	      	                        ' не хватает для покрытия потребности ' +
	      	                        CAST(@qty_need AS VARCHAR(10))
	      	                   WHEN @qty_need > SUM(smai.stor_unit_residues_qty) - ISNULL(SUM(oa.qty), 0) THEN 'Свободного остатка, по выбранным ШК ' + CAST((SUM(smai.stor_unit_residues_qty) - ISNULL(SUM(oa.qty), 0)) AS VARCHAR(10)) 
	      	                        +
	      	                        ', не хватает для покрытия потребности ' + CAST(@qty_need AS VARCHAR(10))
	      	                   ELSE NULL
	      	              END
	FROM	@data_tab dt   
			INNER JOIN	Warehouse.SHKRawMaterialActualInfo smai
				ON	smai.shkrm_id = dt.shkrm_id   
			OUTER APPLY (
			      	SELECT	SUM(smr.quantity) qty
			      	FROM	Warehouse.SHKRawMaterialReserv smr
			      	WHERE	smr.shkrm_id = smai.shkrm_id
			      ) oa
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		DECLARE data_cursor CURSOR 
		FOR
		    SELECT	smai.shkrm_id
		    FROM	@data_tab dt   
		    		INNER JOIN	Warehouse.SHKRawMaterialActualInfo smai
		    			ON	smai.shkrm_id = dt.shkrm_id
		    ORDER BY
		    	smai.stor_unit_residues_qty ASC
		;
		
		OPEN data_cursor;
		
		FETCH NEXT FROM data_cursor
		INTO @shkrm_id;
		
		WHILE @@FETCH_STATUS = 0
		      AND @qty_res > 0
		BEGIN
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
		       		INSERTED.rmid_id,
		       		INSERTED.rmodr_id
		       INTO	@reserv_output (
		       		shkrm_id,
		       		spcvc_id,
		       		okei_id,
		       		quantity,
		       		rmid_id,
		       		rmodr_id
		       	)
		    SELECT	smai.shkrm_id,
		    		@spcvc_id,
		    		@okei_id,
		    		CASE 
		    		     WHEN smai.stor_unit_residues_qty - ISNULL(oar.qty, 0) >= @qty_res THEN @qty_res
		    		     ELSE smai.stor_unit_residues_qty - ISNULL(oar.qty, 0)
		    		END,
		    		@dt,
		    		@employee_id,
		    		NULL,
		    		NULL
		    FROM	Warehouse.SHKRawMaterialActualInfo smai   
		    		OUTER APPLY (
		    		      	SELECT	SUM(smr.quantity) qty
		    		      	FROM	Warehouse.SHKRawMaterialReserv smr
		    		      	WHERE	smr.shkrm_id = smai.shkrm_id
		    		      ) oar
		    WHERE	smai.shkrm_id = @shkrm_id
		    		AND	smai.stor_unit_residues_qty > ISNULL(oar.qty, 0)
		    		AND	@qty_res > 0
		    
		    FETCH NEXT FROM data_cursor
		    INTO @shkrm_id;
		    
		    SET @qty_res = @qty_need -(
		        	SELECT	ISNULL(SUM(ro.quantity), 0)
		        	FROM	@reserv_output ro
		        )
		END
		
		CLOSE data_cursor;
		DEALLOCATE data_cursor;
		
		IF @qty_res > 0
		BEGIN
		    SET @with_log = 0
		    RAISERROR('Не хватило свободного остатка, обновите данные и попробуйте подобрать другой набор ШК', 16, 1)
		    RETURN
		END
		
		INSERT INTO History.SHKRawMaterialReserv
		  (
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
		SELECT	sro.shkrm_id,
				sro.spcvc_id,
				sro.okei_id,
				sro.quantity,
				@dt,
				@employee_id,
				sro.rmid_id,
				sro.rmodr_id,
				@proc_id,
				'I'
		FROM	@reserv_output sro
		
		UPDATE	cvc
		SET 	cs_id = @cvc_state_covered_wh,
				cvc.dt = @dt,
				cvc.employee_id = @employee_id
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
		    			@dt,
		    			@employee_id,
		    			INSERTED.cs_id,
		    			@proc_id
		    	INTO	History.SketchPlanColorVariantCompleting (
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
		FROM	Planing.SketchPlanColorVariantCompleting cvc
		WHERE	cvc.spcvc_id = @spcvc_id
		
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
						INSERTED.cost_plan_month,
						@proc_id
				INTO	History.SketchPlanColorVariant (
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
		FROM	Planing.SketchPlanColorVariant spcv
		WHERE	spcv.sp_id = @sp_id
				AND	cvs_id = @cv_status_create
				AND	NOT EXISTS (
				   		SELECT	1
				   		FROM	Planing.SketchPlanColorVariantCompleting spcvc
				   		WHERE	spcvc.spcv_id = spcv.spcv_id
				   				AND	spcvc.cs_id != @cvc_state_covered_wh
				   	)
		
		UPDATE	sp
		SET 	ps_id = @status_processed_bayer,
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
		WHERE	sp.sp_id = @sp_id
				AND	NOT EXISTS (
				   		SELECT	1
				   		FROM	Planing.SketchPlanColorVariant spcv   
				   				INNER JOIN	Planing.SketchPlanColorVariantCompleting spcvc
				   					ON	spcvc.spcv_id = spcv.spcv_id
				   		WHERE	spcv.sp_id = sp.sp_id
				   				AND	spcvc.cs_id NOT IN (@cvc_state_order_sup, @cvc_state_covered_wh)
				   				AND spcv.is_deleted = 0
				   	) 
				   	
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
		WHERE	sp.sp_id = @sp_id
				AND	NOT EXISTS (
				   		SELECT	1
				   		FROM	Planing.SketchPlanColorVariant spcv   
				   				INNER JOIN	Planing.SketchPlanColorVariantCompleting spcvc
				   					ON	spcvc.spcv_id = spcv.spcv_id
				   		WHERE	spcv.sp_id = sp.sp_id
				   				AND	spcvc.cs_id NOT IN (@cvc_state_covered_wh)
				   				AND	spcv.is_deleted = 0
				)
				
		UPDATE	rmodfr
		SET 	rmods_id        = @rmod_status_deleted,
				employee_id     = @employee_id,
				dt              = @dt
		FROM	Suppliers.RawMaterialStockReserv rmsr
				INNER JOIN	Suppliers.RawMaterialOrderDetailFromReserv rmodfr
					ON	rmodfr.rmsr_id = rmsr.rmsr_id
		WHERE	rmsr.spcvc_id = @spcvc_id
				AND	NOT EXISTS (
				   		SELECT	1
				   		FROM	Material.RawMaterialIncomeOrderReservRelationDetail rmiorrd
				   		WHERE	rmiorrd.rmodr_id = rmodfr.rmodr_id
				   	)
		
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
		    RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess) WITH LOG;
		END
		ELSE
		BEGIN
		    RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess)
		END
	END CATCH 