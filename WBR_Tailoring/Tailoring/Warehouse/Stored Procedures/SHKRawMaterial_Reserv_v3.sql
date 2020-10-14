CREATE PROCEDURE [Warehouse].[SHKRawMaterial_Reserv_v3]
	@spcvc_xml XML,
	@shkrm_xml XML,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @qty_need DECIMAL(9, 3)
	DECLARE @qty_res DECIMAL(9, 3)
	DECLARE @spcvc_id INT
	DECLARE @okei_id INT
	DECLARE @reserv_output TABLE (shkrm_id INT, spcvc_id INT, okei_id INT, quantity DECIMAL(9, 3), rmid_id INT, rmodr_id INT)
	DECLARE @shkrm_id INT
	DECLARE @qty_need_loc DECIMAL(9, 3)
	DECLARE @qty_res_loc DECIMAL(9, 3)
	DECLARE @reserv_output_loc TABLE (shkrm_id INT, spcvc_id INT, okei_id INT, quantity DECIMAL(9, 3), rmid_id INT, rmodr_id INT)
	
	DECLARE @with_log BIT = 1
	DECLARE @proc_id INT	
	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID
	DECLARE @rmod_status_deleted TINYINT = 2 -- удален
	
	
	DECLARE @cvc_state_order_sup TINYINT = 2
	DECLARE @cvc_state_covered_wh TINYINT = 3
	
	DECLARE @cv_status_create TINYINT = 1 --Создан
	DECLARE @cv_status_ready TINYINT = 2 --Цветовариант готов к отшиву
	
	DECLARE @status_processed_bayer TINYINT = 8
	DECLARE @status_complite TINYINT = 4
	
	DECLARE @shkrm_tab TABLE (shkrm_id INT)
	DECLARE @spcvc_tab TABLE (spcvc_id INT, qty_res DECIMAL(9, 3), qty_need DECIMAL(9, 3), rmt_id INT, okei_id INT, sp_id INT)
	
	INSERT INTO @spcvc_tab
		(
			spcvc_id,
			qty_res,
			qty_need,
			rmt_id,
			okei_id,
			sp_id
		)
	SELECT	ml.value('@spcvc[1]', 'int'),
			ISNULL(oar.qty, 0)     qty_res,
			spcvc.consumption * spcv.qty - ISNULL(oar.qty, 0) qty_need,
			spcvc.rmt_id,
			spcvc.okei_id,
			spcv.sp_id
	FROM	@spcvc_xml.nodes('root/det')x(ml)   
			LEFT JOIN	Planing.SketchPlanColorVariantCompleting spcvc   
			INNER JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.spcv_id = spcvc.spcv_id
				ON	spcvc.spcvc_id = ml.value('@spcvc[1]',
			'int')   
			OUTER APPLY (
			      	SELECT	SUM(smr.quantity) qty
			      	FROM	Warehouse.SHKRawMaterialReserv smr
			      	WHERE	smr.spcvc_id = spcvc.spcvc_id
			      )                oar
	
	SELECT	@error_text = CASE 
	      	                   WHEN v.sp_id IS NULL THEN 'Строчки комплектации изделия с кодом ' + CAST(v.spcvc_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN v.qty_need <= 0 THEN 'Количество необходимого материала на ' + s.sa + '(' + an.art_name +
	      	                        ') должно быть больше 0.'
	      	                   ELSE NULL
	      	              END,
			@okei_id = v.okei_id
	FROM	@spcvc_tab v   
			LEFT JOIN	Planing.SketchPlan sp   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = sp.sketch_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id
				ON	sp.sp_id = v.sp_id
	WHERE	v.sp_id IS NULL
			OR	v.qty_need <= 0
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN COUNT(DISTINCT v.rmt_id) > 1 THEN 'Выбранные позиции требуется закрывать разными типами материала'
	      	                   WHEN SUM(v.qty_need) <= 0 THEN 'По выбранным позициям, суммарная потребность, должна быть больше 0.'
	      	                   WHEN COUNT(DISTINCT v.okei_id) > 1 THEN 'Выбранные позиции имеют разные еденицы измерения потребности'
	      	                   WHEN COUNT(*) = 0 THEN 'Не выбрано ни одной позиции для распределения'
	      	                   ELSE NULL
	      	              END,
			@qty_need     = SUM(v.qty_need),
			@qty_res      = SUM(v.qty_need)
	FROM	@spcvc_tab v  			
	
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END	
	
	INSERT INTO @shkrm_tab
		(
			shkrm_id
		)
	SELECT	ml.value('@shkrm[1]', 'int')
	FROM	@shkrm_xml.nodes('root/det')x(ml)   
			LEFT JOIN	Warehouse.SHKRawMaterialActualInfo smai
				ON	smai.shkrm_id = ml.value('@shkrm[1]',
			'int')   
			OUTER APPLY (
			      	SELECT	SUM(smr.quantity) qty
			      	FROM	Warehouse.SHKRawMaterialReserv smr
			      	WHERE	smr.shkrm_id = smai.shkrm_id
			      ) oar
	ORDER BY
		ISNULL(oar.qty, 0) ASC,
		smai.stor_unit_residues_qty DESC
	
	SELECT	@error_text = CASE 
	      	                   WHEN sm.shkrm_id IS NULL THEN 'ШК ' + CAST(dt.shkrm_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN smai.shkrm_id IS NULL THEN 'ШК ' + CAST(dt.shkrm_id AS VARCHAR(10)) + ' не описан'
	      	                   WHEN sms.shkrm_id IS NULL THEN 'ШК ' + CAST(dt.shkrm_id AS VARCHAR(10)) + ' не имеет статуса'
	      	                   WHEN sms.state_id NOT IN (3) THEN 'ШК в статусе ' + smsd.state_name + ', резервировать нельзя.'
	      	                   WHEN smai.stor_unit_residues_okei_id != @okei_id THEN 'ШК ' + CAST(dt.shkrm_id AS VARCHAR(10)) +
	      	                        ' имеет еденицу хранения остатков, отличную от потребности'
	      	                   ELSE NULL
	      	              END
	FROM	@shkrm_tab dt   
			LEFT JOIN	Warehouse.SHKRawMaterial sm
				ON	sm.shkrm_id = dt.shkrm_id   
			LEFT JOIN	Warehouse.SHKRawMaterialActualInfo smai
				ON	smai.shkrm_id = sm.shkrm_id   
			LEFT JOIN	Warehouse.SHKRawMaterialState sms   
			INNER JOIN	Warehouse.SHKRawMaterialStateDict smsd
				ON	smsd.state_id = sms.state_id
				ON	sms.shkrm_id = sm.shkrm_id
	WHERE	sm.shkrm_id IS NULL
			OR	smai.shkrm_id IS NULL
			OR	sms.shkrm_id IS NULL
			OR	sms.state_id NOT IN (3)
			OR	smai.stor_unit_residues_okei_id != @okei_id

	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN SUM(smai.stor_unit_residues_qty) <= SUM(oa.qty) THEN 'Выбранные ШК не имеют свободного остатка'
	      	                   WHEN @qty_need > SUM(smai.stor_unit_residues_qty) THEN 'Остатка по выбранным ШК ' + CAST(SUM(smai.stor_unit_residues_qty) AS VARCHAR(10)) 
	      	                        +
	      	                        ' не хватает для покрытия потребности ' +
	      	                        CAST(@qty_need AS VARCHAR(10))
	      	                   WHEN @qty_need > SUM(smai.stor_unit_residues_qty) - ISNULL(SUM(oa.qty), 0) THEN 'Свободного остатка, по выбранным ШК ' + CAST((SUM(smai.stor_unit_residues_qty) - ISNULL(SUM(oa.qty), 0)) AS VARCHAR(10)) 
	      	                        +
	      	                        ', не хватает для покрытия потребности ' + CAST(@qty_need AS VARCHAR(10))
	      	                   ELSE NULL
	      	              END
	FROM	@shkrm_tab dt   
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
		
		DECLARE spcvc_cursor CURSOR 
		FOR
		    SELECT	dt.spcvc_id,
		    		dt.qty_need,
		    		dt.qty_need
		    FROM	@spcvc_tab dt
		;
		
		OPEN spcvc_cursor;
		FETCH NEXT FROM spcvc_cursor
		INTO @spcvc_id, @qty_need_loc, @qty_res_loc;
		WHILE @@FETCH_STATUS = 0
		BEGIN
		    DECLARE data_cursor CURSOR 
		    FOR
		        SELECT	dt.shkrm_id
		        FROM	@shkrm_tab dt;
		    
		    OPEN data_cursor;
		    
		    FETCH NEXT FROM data_cursor
		    INTO @shkrm_id;    
		    
		    WHILE @@FETCH_STATUS = 0
		          AND @qty_res_loc > 0
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
		        	 INTO	@reserv_output_loc (
		        	 		shkrm_id,
		        	 		spcvc_id,
		        	 		okei_id,
		        	 		quantity,
		        	 		rmid_id,
		        	 		rmodr_id
		        	 	)
		        SELECT	smai.shkrm_id,
		        		@spcvc_id,
		        		smai.okei_id,
		        		CASE 
		        		     WHEN smai.stor_unit_residues_qty - ISNULL(oar.qty, 0) >= @qty_res_loc THEN @qty_res_loc
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
		        		AND	@qty_res_loc > 0
		        		AND	NOT EXISTS (
		        		   		SELECT	1
		        		   		FROM	Warehouse.SHKRawMaterialReserv smr
		        		   		WHERE	smr.shkrm_id = smai.shkrm_id
		        		   				AND	smr.spcvc_id = @spcvc_id
		        		   	)
		        
		        FETCH NEXT FROM data_cursor
		        INTO @shkrm_id;
		        
		        SELECT	@qty_res_loc = @qty_need_loc - ISNULL(SUM(ro.quantity), 0)
		        FROM	@reserv_output_loc ro
		    END
		    
		    SET @qty_res = @qty_res -(@qty_need_loc - @qty_res_loc)
		    
		    DELETE	ro
		          	OUTPUT	DELETED.shkrm_id,
		          			DELETED.spcvc_id,
		          			DELETED.okei_id,
		          			DELETED.quantity,
		          			DELETED.rmid_id,
		          			DELETED.rmodr_id
		          	INTO	@reserv_output (
		          			shkrm_id,
		          			spcvc_id,
		          			okei_id,
		          			quantity,
		          			rmid_id,
		          			rmodr_id
		          		)
		    FROM	@reserv_output_loc ro
		    
		    CLOSE data_cursor;
		    DEALLOCATE data_cursor;
		    FETCH NEXT FROM spcvc_cursor
		    INTO @spcvc_id, @qty_need_loc, @qty_res_loc;
		END
		CLOSE spcvc_cursor;
		DEALLOCATE spcvc_cursor;
		
		IF @qty_res > 0
		BEGIN
		    RAISERROR('Не хватило свободного остатка, обновите данные и попробуйте подобрать другой набор ШК', 16, 1)
		    ROLLBACK TRANSACTION
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
				INNER JOIN	@spcvc_tab st
					ON	st.spcvc_id = cvc.spcvc_id
		
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
		WHERE	cvs_id = @cv_status_create
				AND	NOT EXISTS (
				   		SELECT	1
				   		FROM	Planing.SketchPlanColorVariantCompleting spcvc
				   		WHERE	spcvc.spcv_id = spcv.spcv_id
				   				AND	spcvc.cs_id != @cvc_state_covered_wh
				   	)
				AND	EXISTS (
				   		SELECT	1
				   		FROM	@spcvc_tab st
				   		WHERE	st.sp_id = spcv.sp_id
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
		WHERE	NOT EXISTS (
		     		SELECT	1
		     		FROM	Planing.SketchPlanColorVariant spcv   
		     				INNER JOIN	Planing.SketchPlanColorVariantCompleting spcvc
		     					ON	spcvc.spcv_id = spcv.spcv_id
		     		WHERE	spcv.sp_id = sp.sp_id
		     				AND	spcvc.cs_id NOT IN (@cvc_state_order_sup, @cvc_state_covered_wh)
		     				AND	spcv.is_deleted = 0
		     	)
				AND	EXISTS (
				   		SELECT	1
				   		FROM	@spcvc_tab st
				   		WHERE	st.sp_id = sp.sp_id
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
		WHERE	NOT EXISTS (
		     		SELECT	1
		     		FROM	Planing.SketchPlanColorVariant spcv   
		     				INNER JOIN	Planing.SketchPlanColorVariantCompleting spcvc
		     					ON	spcvc.spcv_id = spcv.spcv_id
		     		WHERE	spcv.sp_id = sp.sp_id
		     				AND	spcvc.cs_id NOT IN (@cvc_state_covered_wh)
		     				AND	spcv.is_deleted = 0
		     	)
				AND	EXISTS (
				   		SELECT	1
				   		FROM	@spcvc_tab st
				   		WHERE	st.sp_id = sp.sp_id
				   	)
		
		UPDATE	rmodfr
		SET 	rmods_id = @rmod_status_deleted,
				employee_id = @employee_id,
				dt = @dt
		FROM	Suppliers.RawMaterialStockReserv rmsr
				INNER JOIN	Suppliers.RawMaterialOrderDetailFromReserv rmodfr
					ON	rmodfr.rmsr_id = rmsr.rmsr_id
				INNER JOIN	@spcvc_tab st
					ON	st.spcvc_id = rmsr.spcvc_id
		WHERE	NOT EXISTS (
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