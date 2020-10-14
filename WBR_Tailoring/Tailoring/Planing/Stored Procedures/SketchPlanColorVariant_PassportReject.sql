CREATE PROCEDURE [Planing].[SketchPlanColorVariant_PassportReject]
	@spcv_id INT,
	@spcvc_xml XML,
	@comment VARCHAR(200) = NULL,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @sp_id INT
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @proc_id INT
	DECLARE @spcvc_tab TABLE (spcvc_id INT)
	
	DECLARE @cv_status_pasport_review TINYINT = 16 --Проверка паспортов ткани дизайнером
	DECLARE @cv_status_placing TINYINT = 12 --Назначен в цех
	DECLARE @cv_status_create TINYINT = 1 --Создан
	DECLARE @status_bayer_repeat TINYINT = 7
	
	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID
	
	SELECT	@error_text = CASE 
	      	                   WHEN spcv.spcv_id IS NULL THEN 'Цветоварианта с кодом ' + CAST(v.spcv_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN spcv.cvs_id NOT IN (@cv_status_pasport_review, @cv_status_placing) THEN 'Статус цветоварианта ' + cvs.cvs_name +
	      	                        ', возвращать к менеджеру по закупкам нельзя.'
	      	                   WHEN oa_c.is_cutting IS NOT NULL THEN 'Внесены данные по крою, отклонять менеджеру нельзя'
	      	                   ELSE NULL
	      	              END,
			@sp_id = spcv.sp_id
	FROM	(VALUES(@spcv_id))v(spcv_id)   
			LEFT JOIN	Planing.SketchPlanColorVariant spcv   
			INNER JOIN	Planing.ColorVariantStatus cvs
				ON	cvs.cvs_id = spcv.cvs_id
				ON	spcv.spcv_id = v.spcv_id   
			OUTER APPLY (
			      	SELECT	TOP(1) 1 is_cutting
			      	FROM	Planing.SketchPlanColorVariantTS spcvt   
			      			INNER JOIN	Manufactory.Cutting c
			      				ON	c.spcvts_id = spcvt.spcvts_id   
			      			INNER JOIN	Manufactory.CuttingActual ca
			      				ON	ca.cutting_id = c.cutting_id
			      	WHERE	spcvt.spcv_id = @spcv_id
			) oa_c
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	INSERT INTO @spcvc_tab
		(
			spcvc_id
		)
	SELECT	ml.value('@spcvc[1]', 'int')
	FROM	@spcvc_xml.nodes('root/det')x(ml)
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	@spcvc_tab st
	   )
	BEGIN
	    RAISERROR('Нет данных по отклоненным элементам комплектации', 16, 1)
	    RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN v.spcvc_id IS NULL THEN 'Не корректный XML'
	      	                   WHEN v.spcvc_id IS NOT NULL AND spcvc.spcvc_id IS NULL THEN 'Строчки комплектации изделия с кодом ' + CAST(v.spcvc_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN spcvc.spcv_id != @spcv_id THEN 'Строчки комплектации изделия с кодом ' + CAST(v.spcvc_id AS VARCHAR(10)) + 
	      	                        ' не относится к отклоняемой модели.'
	      	                   ELSE NULL
	      	              END
	FROM	@spcvc_tab v   
			LEFT JOIN	Planing.SketchPlanColorVariantCompleting spcvc   
			LEFT JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.spcv_id = spcvc.spcv_id
				ON	spcvc.spcvc_id = v.spcvc_id
	WHERE	spcvc.spcvc_id IS NULL
			OR	spcvc.spcv_id != @spcv_id
			OR  v.spcvc_id IS NULL
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION 
		
		UPDATE	sp
		SET 	ps_id = @status_bayer_repeat,
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
		
		UPDATE	spcv
		SET 	cvs_id = @cv_status_create,
				employee_id = @employee_id,
				dt = @dt,
				comment = ISNULL(@comment, comment)
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
		WHERE	spcv.spcv_id = @spcv_id
		
		
		UPDATE	spcvc
		SET 	cs_id = @cv_status_create,
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
				INNER JOIN	@spcvc_tab st
					ON	st.spcvc_id = spcvc.spcvc_id
		
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
				INNER JOIN	@spcvc_tab st
					ON	st.spcvc_id = srmr.spcvc_id 
					
		UPDATE	c
		SET 	plan_count = 0
		FROM	Manufactory.Cutting c
				INNER JOIN	Planing.SketchPlanColorVariantTS spcvt
					ON	spcvt.spcvts_id = c.spcvts_id
		WHERE	spcvt.spcv_id = @spcv_id
		
		UPDATE	spcvt
		SET 	spcvt.cnt = 0,
				spcvt.cut_cnt_for_job = NULL
		FROM	Planing.SketchPlanColorVariantTS spcvt
		WHERE	spcvt.spcv_id = @spcv_id
		
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
	
	