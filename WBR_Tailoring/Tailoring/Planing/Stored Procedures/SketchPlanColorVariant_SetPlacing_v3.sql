CREATE PROCEDURE [Planing].[SketchPlanColorVariant_SetPlacing_v3]
	@data_xml XML,
	@employee_id INT
AS
	SET NOCOUNT ON 
	SET XACT_ABORT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @data_tab TABLE (spcv_id INT, is_mapping BIT)
	DECLARE @cv_status_pre_placing TINYINT = 17 --Подготовлен к запуску
	DECLARE @cv_status_placing TINYINT = 12 --Назначен в цех
	DECLARE @cv_status_confectione_end TINYINT = 10 --Конфекционная карта готова
	DECLARE @proc_id INT
	DECLARE @sketch_tec_job TABLE (sketch_id INT)
	
	
	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID
	
	INSERT INTO @data_tab
		(
			spcv_id,
			is_mapping
		)
	SELECT	ml.value('@spcv', 'int'),
			0
	FROM	@data_xml.nodes('root/det')x(ml)
	
	INSERT INTO @data_tab
		(
			spcv_id,
			is_mapping
		)
	SELECT	aspm.linked_spcv_id,
			1
	FROM	Planing.AddedSketchPlanMapping aspm   
			INNER JOIN	@data_tab st
				ON	aspm.base_spcv_id = st.spcv_id
	
	SELECT	@error_text = CASE 
	      	                   WHEN spcv.spcv_id IS NULL THEN 'Цветоварианта с кодом ' + CAST(dt.spcv_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN spcv.spcv_id IS NOT NULL AND spcv.pan_id IS NULL THEN 'Артикул ' + s.sa + ' не связан с кодом сайта'
	      	                   WHEN (spcv.cvs_id != @cv_status_pre_placing AND ISNULL(sp.season_local_id, 0) != 6) OR
	      	                    (sp.season_local_id = 6 AND spcv.cvs_id != @cv_status_confectione_end) THEN 'Статус цветоварианта ' + spcv.spcv_name + ' артикула ' + s.sa +
	      	                        ' не позволяет назначить его в цех.'
	      	                       
	      	                   WHEN oa.cnt > 1 THEN 'Цветоварианта с кодом ' + CAST(dt.spcv_id AS VARCHAR(10)) + ' указан более одного раза'
	      	                   WHEN s.pt_id IS NULL THEN 'У артикула ' + s.sa + ' не указан тип продукта'
	      	                   WHEN spcv.spcv_id IS NOT NULL AND oa_p.ts_id IS NOT NULL THEN 'У артикула ' + s.sa + ' заполнены не все периметры'
	      	                   WHEN spcv.sew_office_id IS NULL THEN 'У цветоварианта ' + spcv.spcv_name + ' артикула ' + s.sa + ' не указан офис отшива.'
	      	                   WHEN spcv.sew_deadline_dt IS NULL AND ISNULL(sp.season_local_id, 0) != 6 THEN 'У цветоварианта ' + spcv.spcv_name + ' артикула ' + s.sa + ' не указана дата отшива.'
	      	                   WHEN spcv.cost_plan_year IS NULL OR spcv.cost_plan_month IS NULL THEN 'У цветоварианта ' + spcv.spcv_name + ' артикула ' + s.sa +
	      	                        ' не указан период затрат.'
	      	                   ELSE NULL
	      	              END
	FROM	@data_tab dt   
			LEFT JOIN	Planing.SketchPlanColorVariant spcv   
			INNER JOIN	Planing.SketchPlan sp
				ON	sp.sp_id = spcv.sp_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = sp.sketch_id
				ON	spcv.spcv_id = dt.spcv_id   
			OUTER APPLY (
			      	SELECT	COUNT(dt2.spcv_id) cnt
			      	FROM	@data_tab dt2
			      	WHERE	dt2.spcv_id = dt.spcv_id
			      ) oa
	OUTER APPLY (
	      	SELECT	TOP(1) spcvt.ts_id
	      	FROM	Planing.SketchPlanColorVariantTS spcvt   
	      			LEFT JOIN	Products.SketchPatternPerimetr spp
	      				ON	spp.sketch_id = s.sketch_id
	      				AND	spp.ts_id = spcvt.ts_id
	      	WHERE	spcvt.spcv_id = dt.spcv_id
	      			AND	spcvt.cnt != 0
	      			AND	ISNULL(spp.perimetr, 0) = 0
	      ) oa_p
	WHERE	dt.is_mapping = 0
			AND	(
			   		spcv.spcv_id IS NULL
			   		OR spcv.pan_id IS NULL
			   		OR oa.cnt > 1
			   		OR s.pt_id IS NULL
			   		OR oa_p.ts_id IS NOT NULL
			   		OR spcv.cvs_id != @cv_status_pre_placing
			   		OR spcv.sew_office_id IS NULL
			   		OR spcv.sew_deadline_dt IS NULL
			   		OR spcv.cost_plan_year IS NULL
			   		OR spcv.cost_plan_month IS NULL
			   	)
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION
		UPDATE	spcv
		SET 	employee_id = @employee_id,
				dt = @dt,
				cvs_id = @cv_status_placing
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
				INNER JOIN	@data_tab dt
					ON	dt.spcv_id = spcv.spcv_id
		
		UPDATE	s
		SET 	s.technology_dt = @dt
		    	OUTPUT	INSERTED.sketch_id
		    	INTO	@sketch_tec_job (
		    			sketch_id
		    		)
		FROM	Products.Sketch s
		WHERE	EXISTS 
		     	(
		     		SELECT	1
		     		FROM	@data_tab dt   
		     				INNER JOIN	Planing.SketchPlanColorVariant spcv
		     					ON	spcv.spcv_id = dt.spcv_id   
		     				INNER JOIN	Planing.SketchPlan sp
		     					ON	sp.sp_id = spcv.sp_id
		     		WHERE	sp.sketch_id = s.sketch_id
		     	)
				AND	s.technology_dt IS NULL
		
		INSERT INTO Products.SketchTechnologyJob
			(
				sketch_id,
				create_dt,
				create_employee_id,
				qp_id
			)
		SELECT	v.sketch_id,
				@dt,
				@employee_id,
				3
		FROM	@sketch_tec_job v
		WHERE	NOT EXISTS (
		     		SELECT	1
		     		FROM	Products.SketchTechnologyJob stj
		     		WHERE	stj.sketch_id = v.sketch_id
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