CREATE PROCEDURE [Planing].[SketchPlan_ToBayer]
	@sp_id INT,
	@employee_id INT,
	@comment VARCHAR(200) = NULL,
	@qp_id TINYINT = NULL,
	@is_preorder BIT = 0
AS
	SET NOCOUNT ON 
	SET XACT_ABORT ON
	
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @per DECIMAL(5, 2) = 65
	DECLARE @reserv TABLE (spcvc_id INT, reserv_qty DECIMAL(9, 3), need_qty DECIMAL(9, 3))
	DECLARE @cv_status_create TINYINT = 1 --Создан
	DECLARE @cv_status_ready TINYINT = 2 --Цветовариант готов к отшиву	 
	
	DECLARE @state_complite_constructor TINYINT = 10 --Закончено конструирование
	DECLARE @state_appointed_constructor_rework TINYINT = 14 --Назначен на доработку конструктору
	DECLARE @state_constructor_take_job_add_rework TINYINT = 15 --Взят на доработку конструктором
	DECLARE @state_complite_constructor_rework TINYINT = 16 --Доработан конструктором	
	DECLARE @state_need_tect_desig_correction_from_desig TINYINT = 17 --	Тех. эскиз c гот. констр. отпр. на доработку диз-м
	DECLARE @state_tech_design_take_job_amend_from_desig TINYINT = 18 --	Тех. эскиз c гот. констр. взят на дораб-у от диз-а
	DECLARE @state_tech_desig_confirm_from_desig TINYINT = 19 -- Тех. эскиз с готовой конструкцией доработан
	
	DECLARE @states_approve TINYINT = 2
	DECLARE @status_bayer TINYINT = 5
	DECLARE @status_bayer_to_designer TINYINT = 6
	DECLARE @status_bayer_repeat TINYINT = 7
	DECLARE @status_processed_bayer TINYINT = 8
	DECLARE @status_complite TINYINT = 4
	
	DECLARE @cvc_state_need_proc TINYINT = 1
	DECLARE @cvc_state_order_sup TINYINT = 2
	DECLARE @cvc_state_covered_wh TINYINT = 3
	
	DECLARE @proc_id INT
	
	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID
	
	DECLARE @for_pre_plan BIT
	DECLARE @is_new BIT
	DECLARE @cv_qty TINYINT
	DECLARE @plan_qty INT
	DECLARE @spcv_row_count INT
	DECLARE @spcv_sum_qty INT
	
	SELECT	@error_text = CASE 
	      	                   WHEN sp.sp_id IS NULL THEN 'Плана с номером ' + CAST(v.sp_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN sp.ps_id IN (@status_bayer, @status_bayer_repeat) THEN 'Этот эскиз уже отправлен на проработку заказа материалов'
	      	                   WHEN sp.ps_id NOT IN (@states_approve, @status_bayer_to_designer) THEN 'Эскиз находится в статусе ' + ps.ps_name +
	      	                        ' отправлять на проработку заказа ткани нельзя.'
	      	                   WHEN oa.cnt = 0 THEN 'У этой модели нет ни одного цветоварианте, отправлять на проработку заказа ткани нельзя.'
	      	                   WHEN s.construction_close_dt IS NULL AND s.allow_purchase_no_close != 1 THEN 'Не готова конструкция'
	      	                   --WHEN s.ss_id NOT IN (@state_complite_constructor, @state_appointed_constructor_rework, @state_constructor_take_job_add_rework, @state_complite_constructor_rework, 
	      	                   --                    @state_need_tect_desig_correction_from_desig, @state_tech_design_take_job_amend_from_desig, @state_tech_desig_confirm_from_desig) THEN 
	      	                   --     'Текущий статус ' + ss.ss_name  + ' установленый сотрудником с кодом ' + CAST(s.employee_id AS VARCHAR(10)) + ' ' + CONVERT(VARCHAR(20), s.dt, 121) +
	      	                   --     ' не допускает заказа ткани'
	      	                   ELSE NULL
	      	              END,
			@for_pre_plan  = CASE 
			                     WHEN sp.spp_id IS NULL THEN 0
			                     ELSE 1
			                END,
			@is_new       = CASE 
			               WHEN sp.ps_id = @states_approve THEN 1
			               ELSE 0
			          END,
			@plan_qty                = sp.plan_qty,
			@cv_qty                  = sp.cv_qty,
			@spcv_row_count = oa.cnt,
			@spcv_sum_qty = oa.sum_qty
	FROM	(VALUES(@sp_id))v(sp_id)   
			LEFT JOIN	Planing.SketchPlan sp   
			INNER JOIN	Planing.PlanStatus ps
				ON	ps.ps_id = sp.ps_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = sp.sketch_id   
			INNER JOIN	Products.SketchStatus ss
				ON	ss.ss_id = s.ss_id
				ON	sp.sp_id = v.sp_id   
			OUTER APPLY (
			      	SELECT	COUNT(1) cnt, 
			      			SUM(spcv.qty) sum_qty
			      	FROM	Planing.SketchPlanColorVariant spcv
			      	WHERE	spcv.sp_id = sp.sp_id
			      ) oa	
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN ISNULL(oa.cnt, 0) = 0 THEN 'Для цветоварианта ' + spcv.spcv_name + ' не указанв комплектация.'
	      	                   WHEN ISNULL(oa.cons, 0) <= 0 THEN 'Есть незаплненный расход'
	      	                        --WHEN oa_dif.spcvc_id IS NULL OR oa_dif.sc_id IS NULL THEN 'Есть несовпадение с текущей нормой расхода'
	      	                   ELSE NULL
	      	              END	      	              
	FROM	Planing.SketchPlan sp   
			LEFT JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.sp_id = sp.sp_id   
			OUTER APPLY (
			      	SELECT	COUNT(spcvc.spcvc_id) cnt,
			      			MIN(spcvc.consumption) cons
			      	FROM	Planing.SketchPlanColorVariantCompleting spcvc
			      	WHERE	spcvc.spcv_id = spcv.spcv_id
			      ) oa
	--OUTER APPLY (
	--    			SELECT	TOP(1) spcvc.spcvc_id,
	--    					sc.sc_id
	--    			FROM	Planing.SketchPlanColorVariantCompleting spcvc
	--    					FULL JOIN	Products.SketchCompleting sc
	--    						ON	sc.completing_id = spcvc.completing_id
	--    						AND	sc.completing_number = spcvc.completing_number
	--    						AND	sc.okei_id = spcvc.okei_id
	--    						AND	sc.consumption = spcvc.consumption
	--    						AND	sc.frame_width = spcvc.frame_width
	--    			WHERE	sc.sketch_id = sp.sketch_id
	--    					AND	spcvc.spcv_id = spcv.spcv_id
	--    					AND	(spcvc.completing_id IS NULL OR sc.completing_id IS NULL)
	--	  ) oa_dif
	WHERE	sp.sp_id = @sp_id
			AND	spcv.is_deleted = 0
			AND	(
			   		ISNULL(oa.cnt, 0) = 0
			   		OR 
			   		   ISNULL(oa.cons, 0) <= 0 
			   		   --OR oa_dif.spcvc_id IS NULL OR oa_dif.sc_id IS NULL
			   	)
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	INSERT INTO @reserv
		(
			spcvc_id,
			reserv_qty,
			need_qty
		)
	SELECT	spcvc.spcvc_id,
			ISNULL(oa.reserv_qty, 0)     reserv_qty,
			spcvc.consumption * spcv.qty
	FROM	Planing.SketchPlanColorVariantCompleting spcvc   
			INNER JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.spcv_id = spcvc.spcv_id   
			OUTER APPLY (
			      	SELECT	SUM(smr.quantity) reserv_qty
			      	FROM	Warehouse.SHKRawMaterialReserv smr
			      	WHERE	smr.spcvc_id = spcvc.spcvc_id
			      )                      oa 
	WHERE spcv.sp_id = @sp_id
	
	IF @qp_id IS NOT NULL AND NOT EXISTS (
	   	SELECT	1
	   	FROM	Products.QueuePriority qp
	   	WHERE	qp.qp_id = @qp_id
	   )
	BEGIN
	    RAISERROR('Приоритета с кодом %d не существует', 16, 1, @qp_id)
	    RETURN
	END
	
	BEGIN TRY
	BEGIN TRANSACTION 
	
		IF @is_new = 1
		   AND @for_pre_plan = 1
		   AND @cv_qty > @spcv_row_count
		   AND @plan_qty > @spcv_sum_qty
		BEGIN		   		    
		    INSERT INTO Planing.SketchPlan
		    	(
		    		sketch_id,
		    		ps_id,
		    		create_employee_id,
		    		create_dt,
		    		employee_id,
		    		dt,
		    		comment,
		    		plan_year,
		    		plan_month,
		    		sew_office_id,
		    		to_purchase_dt,
		    		qp_id,
		    		plan_qty,
		    		cv_qty,
		    		plan_sew_dt,
		    		spp_id,
		    		season_local_id,
		    		is_preorder		    		
		    	)OUTPUT	INSERTED.sp_id,
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
		    SELECT	sp.sketch_id,
		    		sp.ps_id,
		    		sp.create_employee_id,
		    		@dt,
		    		sp.employee_id,
		    		sp.dt,
		    		'2я Часть неполного запуска ' + isnull(sp.comment, '') comment,
		    		sp.plan_year,
		    		sp.plan_month,
		    		sp.sew_office_id,
		    		@dt,
		    		sp.qp_id,
		    		@plan_qty - @spcv_sum_qty,
		    		@cv_qty - @spcv_row_count,
		    		sp.plan_sew_dt,
		    		sp.spp_id,
		    		sp.season_local_id,
		    		@is_preorder
		    FROM	Planing.SketchPlan sp
		    WHERE	sp.sp_id = @sp_id
		END
	
		UPDATE	Planing.SketchPlan
		SET 	ps_id              = CASE 
		    	             WHEN ps_id = @states_approve THEN @status_bayer
		    	             ELSE @status_bayer_repeat
		    	        END,
				employee_id        = @employee_id,
				dt                 = @dt,
				to_purchase_dt     = ISNULL(to_purchase_dt, @dt),
				comment            = CASE 
				                WHEN @is_new = 1
				                     AND @for_pre_plan = 1
				                     AND @cv_qty > @spcv_row_count
				                     AND @plan_qty > @spcv_sum_qty THEN ISNULL(@comment, 'Часть запуска ' + isnull(comment, '')) 
				                     	ELSE
				                     	ISNULL(@comment, comment)
				                     	END,
				qp_id              = @qp_id,
				plan_qty           = CASE 
				                WHEN @is_new = 1
				                     AND @for_pre_plan = 1
				                     AND @cv_qty > @spcv_row_count
				                     AND @plan_qty > @spcv_sum_qty THEN @spcv_sum_qty
				                ELSE plan_qty
				           END,
				cv_qty = CASE 
				              WHEN @is_new = 1
				                   AND @for_pre_plan = 1
				                   AND @cv_qty > @spcv_row_count
				                   AND @plan_qty > @spcv_sum_qty THEN @spcv_row_count
				              ELSE cv_qty
				         END,
				is_preorder = @is_preorder		
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
		WHERE	sp_id = @sp_id
				AND	ps_id IN (@states_approve, @status_bayer_to_designer)
		
		IF @@ROWCOUNT = 0
		BEGIN
		    RAISERROR('Перечитайте данные, статус уже изменен.', 16, 1)
		    RETURN
		END
		
		UPDATE	spcvc
		SET 	cs_id           = @cvc_state_covered_wh,
				employee_id     = @employee_id,
				dt              = @dt
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
		FROM	Planing.SketchPlanColorVariantCompleting spcvc
				INNER JOIN	@reserv r
					ON	r.spcvc_id = spcvc.spcvc_id
		WHERE	(CASE 
		     	      WHEN r.need_qty = 0 THEN 1
		     	      WHEN r.need_qty <= r.reserv_qty THEN 1
		     	      WHEN (r.need_qty > 0 AND 100 * r.reserv_qty / r.need_qty >= @per) THEN 1
		     	      ELSE 0
		     	 END) = 1
				AND	spcvc.cs_id != @cvc_state_covered_wh
				AND spcvc.consumption != 0
		
		UPDATE	spcv
		SET 	cvs_id          = @cv_status_ready,
				employee_id     = @employee_id,
				dt              = @dt
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
				AND	spcv.sp_id = @sp_id
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
				   				AND	spcv.is_deleted = 0
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
				
		INSERT INTO Planing.SketchPlanColorVariantCompleting
			(
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
			)OUTPUT	INSERTED.spcvc_id,
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
		SELECT	spcv.spcv_id,
				32,
				1,
				54,
				0,
				NULL,
				616,
				0.001,
				NULL,
				@dt,
				@employee_id,
				@cvc_state_covered_wh
		FROM	Planing.SketchPlanColorVariant spcv
		WHERE	spcv.sp_id = @sp_id
				AND	spcv.is_deleted = 0
				AND	NOT EXISTS (
				   		SELECT	1
				   		FROM	Planing.SketchPlanColorVariantCompleting spcvc
				   		WHERE	spcvc.spcv_id = spcv.spcv_id
				   				AND	spcvc.completing_id = 32
				   				AND	spcvc.completing_number = 1
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
		
		RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess) 
		WITH LOG;
	END CATCH 
	