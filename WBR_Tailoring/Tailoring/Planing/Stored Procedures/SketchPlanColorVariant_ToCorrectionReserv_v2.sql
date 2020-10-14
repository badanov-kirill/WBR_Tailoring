CREATE PROCEDURE [Planing].[SketchPlanColorVariant_ToCorrectionReserv_v2]
	@spcv_xml XML,
	@employee_id INT,
	@comment VARCHAR(300) = NULL
AS
	SET NOCOUNT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @spcv_tab TABLE (spcv_id INT, is_added BIT)
	DECLARE @sp_tab TABLE (sp_id INT, sketch_id INT)
	DECLARE @output_stj TABLE (stj_id INT, sp_id INT)
	DECLARE @cv_status_ready TINYINT = 2 --Зарезервировано
	DECLARE @cv_status_sel_pasp TINYINT = 3 --Сбор паспортов на материал
	DECLARE @cv_status_corr_reserv TINYINT = 5 --На изменение резервов
	DECLARE @cv_status_confectione_end TINYINT = 10 --Конфекционная карта готова
	DECLARE @cv_status_placing TINYINT = 12 --Назначен в цех
	DECLARE @cv_status_layout_close TINYINT = 8 --Раскладка привязана	
	DECLARE @cv_status_pasport_review TINYINT = 16 --Проверка паспортов ткани дизайнером
	
	DECLARE @proc_id INT
	
	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID
	
	INSERT INTO @spcv_tab
		(
			spcv_id,
			is_added
		)
	SELECT	ml.value('@spcv', 'int'),
			0
	FROM	@spcv_xml.nodes('root/det')x(ml)
	
	INSERT INTO @spcv_tab
		(
			spcv_id,
			is_added
		)
	SELECT	aspm.linked_spcv_id,
			1
	FROM	Planing.AddedSketchPlanMapping aspm   
			INNER JOIN	@spcv_tab st
				ON	aspm.base_spcv_id = st.spcv_id
	
	SELECT	@error_text = CASE 
	      	                   WHEN spcv.spcv_id IS NULL THEN 'Цветоварианта с кодом ' + CAST(dt.spcv_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN spcv.cvs_id NOT IN (@cv_status_ready, @cv_status_sel_pasp, @cv_status_confectione_end, @cv_status_placing, @cv_status_pasport_review) 
	      	                        AND dt.is_added = 0 THEN 'Статус цветоварианта ' + spcv.spcv_name + ' артикула ' + s.sa + ' - "' + cvs.cvs_name +
	      	                        '" не позволяет отправить его конфекционеру.'
	      	                   WHEN oa.cnt > 1 THEN 'Цветоварианта с кодом ' + CAST(dt.spcv_id AS VARCHAR(10)) + ' указан более одного раза'
	      	                   ELSE NULL
	      	              END
	FROM	@spcv_tab dt   
			LEFT JOIN	Planing.SketchPlanColorVariant spcv   
			INNER JOIN	Planing.SketchPlan sp
				ON	sp.sp_id = spcv.sp_id   
			INNER JOIN	Planing.ColorVariantStatus cvs
				ON	cvs.cvs_id = spcv.cvs_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = sp.sketch_id
				ON	spcv.spcv_id = dt.spcv_id   
			OUTER APPLY (
			      	SELECT	COUNT(dt2.spcv_id) cnt
			      	FROM	@spcv_tab dt2
			      	WHERE	dt2.spcv_id = dt.spcv_id
			      ) oa
	WHERE	spcv.spcv_id IS NULL
			OR	(spcv.cvs_id NOT IN (@cv_status_ready, @cv_status_sel_pasp, @cv_status_confectione_end, @cv_status_placing, @cv_status_pasport_review) AND dt.is_added = 0)
			OR	oa.cnt > 1
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	INSERT INTO @sp_tab
		(
			sp_id,
			sketch_id
		)
	SELECT	spcv.sp_id,
			sp.sketch_id
	FROM	@spcv_tab dt   
			INNER JOIN	Planing.SketchPlanColorVariant spcv   
			INNER JOIN	Planing.SketchPlan sp
				ON	sp.sp_id = spcv.sp_id
				ON	spcv.spcv_id = dt.spcv_id   
	
	BEGIN TRY
		UPDATE	spcv
		SET 	cvs_id = CASE 
		    	              WHEN cvs_id IN (@cv_status_confectione_end, @cv_status_placing) THEN @cv_status_layout_close
		    	              ELSE @cv_status_corr_reserv
		    	         END,
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
				INNER JOIN	@spcv_tab st
					ON	st.spcv_id = spcv.spcv_id
		WHERE	cvs_id IN (@cv_status_ready, @cv_status_sel_pasp, @cv_status_confectione_end, @cv_status_placing, @cv_status_pasport_review)
		
		IF @@ROWCOUNT = 0
		BEGIN
		    RAISERROR('Статус не позволяет перехода.', 16, 1)
		    RETURN
		END
		
		IF @comment IS NOT NULL
		BEGIN
		    INSERT INTO Planing.SketchPlanColorVariantComment
		    	(
		    		spcv_id,
		    		dt,
		    		employee_id,
		    		ct_id,
		    		comment
		    	)
		    SELECT	st.spcv_id,
		    		@dt,
		    		@employee_id,
		    		2,
		    		@comment
		    FROM	@spcv_tab st
		END;
		
		MERGE Products.SketchTechnologyJob t
		USING (
		      	SELECT	st.sketch_id,
		      			st.sp_id
		      	FROM	@sp_tab st
		      	WHERE	NOT EXISTS (
		      	     		SELECT	1
		      	     		FROM	Planing.SketchPlanTechologyJob sptj
		      	     		WHERE	sptj.sp_id = st.sp_id
		      	     	)
		      )s
				ON t.sketch_id = s.sketch_id
				AND t.end_dt IS NULL
		WHEN MATCHED THEN 
		     UPDATE	
		     SET 	t.qp_id = 1,
		     		t.stjt_id = 2
		WHEN NOT MATCHED THEN 
		     INSERT
		     	(
		     		sketch_id,
		     		create_dt,
		     		create_employee_id,
		     		begin_dt,
		     		begin_employee_id,
		     		end_dt,
		     		qp_id,
		     		stjt_id
		     	)
		     VALUES
		     	(
		     		s.sketch_id,
		     		@dt,
		     		@employee_id,
		     		NULL,
		     		NULL,
		     		NULL,
		     		1,
		     		2
		     	) 
		     OUTPUT	INSERTED.stj_id,
		     		s.sp_id
		     INTO	@output_stj (
		     		stj_id,
		     		sp_id
		     	);
		
		INSERT INTO Planing.SketchPlanTechologyJob
			(
				sp_id,
				stj_id,
				create_dt
			)
		SELECT	os.sp_id,
				os.stj_id,
				@dt
		FROM	@output_stj os
			
		
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