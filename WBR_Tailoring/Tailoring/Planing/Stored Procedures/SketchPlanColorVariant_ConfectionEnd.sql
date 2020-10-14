CREATE PROCEDURE [Planing].[SketchPlanColorVariant_ConfectionEnd]
	@spcv_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	
	DECLARE @cv_status_layout_close TINYINT = 8 --Раскладка привязана
	DECLARE @cv_status_confectione_end TINYINT = 10 --Конфекционная карта готова
	DECLARE @cv_status_cancelling TINYINT = 13 --Отклонен конфекционером
	DECLARE @proc_id INT
	DECLARE @reserv TABLE (spcvc_id INT, shkrm_id INT, okei_id INT, quantity DECIMAL(9, 3), pre_cost DECIMAL(9, 2))
	DECLARE @corrected_qty SMALLINT
	DECLARE @base_technolog_employee_id INT
	DECLARE @plan_dt DATE
	DECLARE @season_local_id INT
	DECLARE @cutting_tariff DECIMAL(9,6)

	
	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID
	
	SELECT	@error_text = CASE 
	      	                   WHEN spcv.spcv_id IS NULL THEN 'Цветоварианта с кодом ' + CAST(v.spcv_id AS VARCHAR(10)) +
	      	                        ' не существует.'
	      	                   WHEN spcv.cvs_id NOT IN (@cv_status_layout_close) AND spcv.corrected_qty > 0 THEN 'Статус цветоварианта ' + cvs.cvs_name +
	      	                        ', перевод в статус окончание комплектования запрещен.'
	      	                   WHEN spcv.pan_id IS NULL AND spcv.corrected_qty > 0 THEN 'Не привязан цветовариант.'
	      	                   WHEN spcv.corrected_qty IS NULL THEN 'Не указано запускаемое количество'
	      	                   WHEN ISNULL(oa.cnt, 0) != ISNULL(spcv.corrected_qty, 0) THEN 'Не совпадает запускаемое количество с количеством по размерам'
	      	                   ELSE NULL
	      	              END,
	      	@corrected_qty = spcv.corrected_qty,
	      	@base_technolog_employee_id = s.technology_employee_id,
	      	@plan_dt = sp.plan_sew_dt,
	      	@season_local_id = sp.season_local_id,
	      	@cutting_tariff = os.cutting_tariff
	FROM	(VALUES(@spcv_id))v(spcv_id)   
			LEFT JOIN	Planing.SketchPlanColorVariant spcv   
			INNER JOIN	Planing.ColorVariantStatus cvs
				ON	cvs.cvs_id = spcv.cvs_id
			INNER JOIN Planing.SketchPlan sp ON sp.sp_id = spcv.sp_id
			INNER JOIN Products.Sketch s ON s.sketch_id = sp.sketch_id
				ON	spcv.spcv_id = v.spcv_id  
			LEFT JOIN Settings.OfficeSetting os
				ON os.office_id = spcv.sew_office_id
			OUTER APPLY (
			      	SELECT	SUM(spcvt.cnt) cnt
			      	FROM	Planing.SketchPlanColorVariantTS spcvt
			      	WHERE	spcvt.spcv_id = v.spcv_id
			      )  oa
	
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	SELECT	@error_text = 'На ' + c.completing_name + CAST(spcvc.completing_number AS VARCHAR(10)) + ' потребность ' + CAST(ISNULL(oa_lay.consumption, spcvc.consumption) * ISNULL(spcv.corrected_qty, spcv.qty) AS VARCHAR(10)) 
	      	+ ' , а зарезервировано ' + CAST(ISNULL(oar.qty, 0) AS VARCHAR(10)) + '. Скорректируйте количество, либо добавьте резервов.'
	FROM	Planing.SketchPlanColorVariantCompleting spcvc   
			INNER JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.spcv_id = spcvc.spcv_id   
			INNER JOIN	Material.Completing c
				ON	c.completing_id = spcvc.completing_id   
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = spcvc.rmt_id   
			OUTER APPLY (
			      	SELECT	TOP(1) l.frame_width, tl.tl_id
			      	FROM	Manufactory.TaskLayout tl   
			      			INNER JOIN	Manufactory.TaskLayoutDetail tld
			      				ON	tld.tl_id = tl.tl_id   
			      			INNER JOIN	Manufactory.Layout l
			      				ON	l.layout_id = tld.layout_id
			      	WHERE	tl.spcv_id = spcv.spcv_id
			      			AND	l.base_completing_id = spcvc.completing_id
			      			AND	l.base_completing_number = spcvc.completing_number
			      			AND	l.is_deleted = 0
			      	ORDER BY
			      		tl.tl_id DESC, l.frame_width ASC
			      ) oa_lay_fw
			OUTER APPLY (
	      			SELECT	AVG(l.base_consumption) consumption
	      			FROM	Manufactory.TaskLayout tl   
	      					INNER JOIN	Manufactory.TaskLayoutDetail tld
	      						ON	tld.tl_id = tl.tl_id   
	      					INNER JOIN	Manufactory.Layout l
	      						ON	l.layout_id = tld.layout_id
	      			WHERE	tl.spcv_id = spcv.spcv_id
	      					AND	l.base_completing_id = spcvc.completing_id
	      					AND	l.base_completing_number = spcvc.completing_number
	      					AND	l.is_deleted = 0
	      					AND	l.frame_width = oa_lay_fw.frame_width
	      					AND tl.tl_id = oa_lay_fw.tl_id
				  )              oa_lay
			OUTER APPLY (
	      			SELECT	SUM(smr.quantity) qty
	      			FROM	Warehouse.SHKRawMaterialReserv smr
	      			WHERE	smr.spcvc_id = spcvc.spcvc_id
				  ) oar
	WHERE	spcvc.spcv_id = @spcv_id
			AND	ISNULL(oa_lay.consumption, spcvc.consumption) * ISNULL(spcv.corrected_qty, spcv.qty) > ISNULL(oar.qty, 0) 
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN spcv.pan_id IS NULL THEN 'Не привязан цветовариант компаньена.'
	      	                   WHEN spcv.corrected_qty IS NULL THEN 'Не указано запускаемое количество компаньена'
	      	                   ELSE NULL
	      	              END
	FROM	Planing.AddedSketchPlanMapping aspm   
			INNER JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.spcv_id = aspm.linked_spcv_id
	WHERE	base_spcv_id = @spcv_id
			AND	spcv.is_deleted = 0
			AND	(spcv.pan_id IS NULL OR spcv.corrected_qty IS NULL)
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	INSERT INTO @reserv
		(
			spcvc_id,
			shkrm_id,
			okei_id,
			quantity,
			pre_cost
		)
	SELECT	spcvc.spcvc_id,
			smr.shkrm_id,
			smr.okei_id,
			smr.quantity,
			COALESCE(sma0.amount / sma0.stor_unit_residues_qty,oa1.price, oa2.price, oa3.price, 0) * smr.quantity pre_cost
	FROM	Planing.SketchPlanColorVariantCompleting spcvc 
			INNER JOIN	Warehouse.SHKRawMaterialReserv smr
				ON	smr.spcvc_id = spcvc.spcvc_id   
			INNER JOIN	Warehouse.SHKRawMaterialActualInfo smai
				ON	smai.shkrm_id = smr.shkrm_id   
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = smai.rmt_id 
			LEFT JOIN Warehouse.SHKRawMaterialAmount sma0
				ON sma0.shkrm_id = smr.shkrm_id AND sma0.final_dt IS NOT NULL AND sma0.amount != 0   
			OUTER APPLY (
			      	SELECT	AVG(v.price) price
			      	FROM	(SELECT	TOP(10) sma.amount / sma.stor_unit_residues_qty price
			      	    	 FROM	Warehouse.SHKRawMaterialAmount sma   
			      	    	 		INNER JOIN	Warehouse.SHKRawMaterialInfo smi
			      	    	 			ON	smi.shkrm_id = sma.shkrm_id
			      	    	 WHERE	smi.rmt_id = smai.rmt_id
			      	    	 		AND	smi.art_id = smai.art_id
			      	    	 		AND	sma.final_dt IS NOT NULL
			      	    	 		AND	sma.amount != 0
			      	    	 ORDER BY
			      	    	 	sma.final_dt DESC)v
			      ) oa1
			OUTER APPLY (
	      			SELECT	AVG(v.price) price
	      			FROM	(SELECT	TOP(10) sma.amount / sma.stor_unit_residues_qty price
	      	    			 FROM	Warehouse.SHKRawMaterialAmount sma   
	      	    	 				INNER JOIN	Warehouse.SHKRawMaterialInfo smi
	      	    	 					ON	smi.shkrm_id = sma.shkrm_id
	      	    			 WHERE	smi.rmt_id = smai.rmt_id
	      	    	 				AND	sma.final_dt IS NOT NULL
	      	    	 				AND	sma.amount != 0
	      	    			 ORDER BY
	      	    	 			sma.final_dt DESC)v
				  ) oa2
			OUTER APPLY (
	      			SELECT	AVG(v.price) price
	      			FROM	(SELECT	TOP(10) sma.amount / sma.stor_unit_residues_qty price
	      	    			 FROM	Warehouse.SHKRawMaterialAmount sma   
	      	    	 				INNER JOIN	Warehouse.SHKRawMaterialInfo smi
	      	    	 					ON	smi.shkrm_id = sma.shkrm_id   
	      	    	 				INNER JOIN	Material.RawMaterialType rmt2
	      	    	 					ON	rmt2.rmt_id = smi.rmt_id
	      	    			 WHERE	rmt.rmt_pid = rmt2.rmt_pid
	      	    	 				AND	sma.final_dt IS NOT NULL
	      	    	 				AND	sma.amount != 0
	      	    			 ORDER BY
	      	    	 			sma.final_dt DESC)v
				  ) oa3
	WHERE spcvc.spcv_id = @spcv_id
	
	BEGIN TRY
		BEGIN TRANSACTION
		UPDATE	spcv
		SET 	cvs_id = CASE 
		    	              WHEN corrected_qty = 0 THEN @cv_status_cancelling
		    	              ELSE @cv_status_confectione_end
		    	         END,
				employee_id = @employee_id,
				dt = @dt,
				pre_cost = CASE 
				                WHEN corrected_qty = 0 THEN 0
				                ELSE oa.pre_cost
				           END
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
		FROM Planing.SketchPlanColorVariant spcv
				OUTER APPLY (
				      	SELECT	SUM(cr.pre_cost) pre_cost
				      	FROM	@reserv cr
				      ) oa
		WHERE	spcv_id = @spcv_id
				AND	(cvs_id = @cv_status_layout_close OR corrected_qty = 0)
		
		IF @@ROWCOUNT = 0
		BEGIN
		    RAISERROR('Статус не позволяет перехода.', 16, 1)
		    RETURN
		END
		
		IF @season_local_id = 6
		BEGIN
			;
			MERGE Manufactory.Cutting t
			USING (
		      		SELECT	spcv.sew_office_id office_id,
		      				spcv.cost_plan_year      plan_year,
		      				spcv.cost_plan_month     plan_month,
		      				pants.pants_id,
		      				@employee_id         employee_id,
		      				@dt                  dt,
		      				spcvt.cnt            plan_count,
		      				spp.perimetr         perimeter,
		      				s.pt_id,
		      				@dt plan_start_dt,
		      				spcvt.spcvts_id,
		      				@cutting_tariff      cutting_tariff
		      		FROM	Planing.SketchPlanColorVariant spcv   
		      				INNER JOIN	Planing.SketchPlan sp
		      					ON	sp.sp_id = spcv.sp_id   
		      				INNER JOIN	Products.Sketch s
		      					ON	s.sketch_id = sp.sketch_id   
		      				INNER JOIN	Planing.SketchPlanColorVariantTS spcvt
		      					ON	spcvt.spcv_id = spcv.spcv_id   
		      				INNER JOIN	Products.SketchPatternPerimetr spp
		      					ON	spp.sketch_id = s.sketch_id
		      					AND	spp.ts_id = spcvt.ts_id   
		      				INNER JOIN	Products.ProdArticleNomenclatureTechSize pants
		      					ON	pants.pan_id = spcv.pan_id
		      					AND	pants.ts_id = spcvt.ts_id   
		      		WHERE spcv.spcv_id = @spcv_id
				  ) s
					ON t.spcvts_id = s.spcvts_id
			WHEN MATCHED THEN 
				 UPDATE	
				 SET 	employee_id       = s.employee_id,
		     			dt                = s.dt,
		     			plan_count        = s.plan_count,
		     			perimeter         = s.perimeter,
		     			pt_id             = s.pt_id,
		     			plan_start_dt     = s.plan_start_dt,
		     			office_id         = s.office_id,
		     			plan_year         = s.plan_year,
		     			plan_month        = s.plan_month,
		     			pants_id          = s.pants_id,
		     			cutting_tariff	  = s.cutting_tariff
			WHEN NOT MATCHED BY TARGET THEN 
				 INSERT
		     		(
		     			office_id,
		     			plan_year,
		     			plan_month,
		     			pants_id,
		     			plan_count,
		     			create_employee_id,
		     			create_dt,
		     			employee_id,
		     			dt,
		     			perimeter,
		     			pt_id,
		     			plan_start_dt,
		     			spcvts_id,
		     			cutting_tariff
		     		)
				 VALUES
		     		(
		     			s.office_id,
		     			s.plan_year,
		     			s.plan_month,
		     			s.pants_id,
		     			s.plan_count,
		     			s.employee_id,
		     			s.dt,
		     			s.employee_id,
		     			s.dt,
		     			s.perimeter,
		     			s.pt_id,
		     			s.plan_start_dt,
		     			s.spcvts_id,
		     			s.cutting_tariff
		     		);
		END
		
		IF @corrected_qty = 0
		BEGIN
			UPDATE	c
			SET 	plan_count = 0
			FROM	Manufactory.Cutting c
					INNER JOIN	Planing.SketchPlanColorVariantTS spcvt
						ON	spcvt.spcvts_id = c.spcvts_id
					INNER JOIN	Planing.SketchPlanColorVariant spcv
						ON	spcv.spcv_id = spcvt.spcv_id
			WHERE	spcv.spcv_id = @spcv_id
			
			DELETE	srmr
			      	OUTPUT	DELETED.shkrm_id,
			      			DELETED.spcvc_id,
			      			DELETED.okei_id,
			      			DELETED.quantity,
			      			@dt,
			      			@employee_id,
			      			DELETED.rmid_id,
			      			DELETED.rmodr_id,
			      			@proc_id,
			      			'D'
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
			FROM	Warehouse.SHKRawMaterialReserv srmr   
					INNER JOIN	Planing.SketchPlanColorVariantCompleting spcvc
						ON	spcvc.spcvc_id = srmr.spcvc_id
			WHERE	spcvc.spcv_id = @spcv_id
		END
		ELSE 
		BEGIN 
			;
			WITH cte_Target AS
				(
					SELECT	pcr.ccr_id,
							pcr.spcvc_id,
							pcr.shkrm_id,
							pcr.okei_id,
							pcr.qty,
							pcr.dt,
							pcr.employee_id,
							pcr.pre_cost
					FROM	Planing.PreCostReserv pcr   
							INNER JOIN	Planing.SketchPlanColorVariantCompleting spcvc
								ON	spcvc.spcvc_id = pcr.spcvc_id
					WHERE	spcvc.spcv_id = @spcv_id
				)
			MERGE cte_target t
			USING @reserv s
					ON s.spcvc_id = t.spcvc_id
					AND s.shkrm_id = t.shkrm_id
			WHEN MATCHED THEN 
				 UPDATE	
				 SET 	okei_id         = s.okei_id,
		     			qty             = s.quantity,
		     			pre_cost        = s.pre_cost,
		     			employee_id     = @employee_id,
		     			dt              = @dt
			WHEN NOT MATCHED BY TARGET THEN 
				 INSERT
		     		(
		     			spcvc_id,
		     			shkrm_id,
		     			okei_id,
		     			qty,
		     			dt,
		     			employee_id,
		     			pre_cost
		     		)
				 VALUES
		     		(
		     			s.spcvc_id,
		     			s.shkrm_id,
		     			s.okei_id,
		     			s.quantity,
		     			@dt,
		     			@employee_id,
		     			s.pre_cost
		     		)
			WHEN NOT MATCHED BY SOURCE THEN 
				 DELETE	;
		END

		INSERT INTO Manufactory.SPCV_ForTechSeq
			(
				spcv_id,
				create_dt,
				qp_id,
				base_technolog_employee_id,
				plan_dt
			)
		SELECT	@spcv_id,
				@dt,
				2,
				@base_technolog_employee_id,
				@plan_dt
		WHERE	NOT EXISTS (
		     		SELECT	1
		     		FROM	Manufactory.SPCV_ForTechSeq sfts
		     		WHERE	sfts.spcv_id = @spcv_id
		     				AND	sfts.start_dt IS NULL
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