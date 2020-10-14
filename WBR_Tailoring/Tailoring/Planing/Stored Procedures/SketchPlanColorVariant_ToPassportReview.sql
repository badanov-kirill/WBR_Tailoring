CREATE PROCEDURE [Planing].[SketchPlanColorVariant_ToPassportReview]
	@spcv_id INT,
	@employee_id INT
AS
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	
	DECLARE @cv_status_ready TINYINT = 2 --Зарезервировано
	DECLARE @cv_status_sel_pasp TINYINT = 3 --Сбор паспортов на материал
	DECLARE @cv_status_pasport_review TINYINT = 16 --Проверка паспортов ткани дизайнером
	DECLARE @cvc_state_covered_wh TINYINT = 3
	
	DECLARE @proc_id INT
	
	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID
	
	SELECT	@error_text = CASE 
	      	                   WHEN spcv.spcv_id IS NULL THEN 'Цветоварианта с кодом ' + CAST(v.spcv_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN spcv.cvs_id NOT IN (@cv_status_ready, @cv_status_sel_pasp) THEN 
	      	                        'Статус цветоварианта ' + cvs.cvs_name +
	      	                        ', перевод на измение резервов запрещен.'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@spcv_id))v(spcv_id)   
			LEFT JOIN	Planing.SketchPlanColorVariant spcv   
			INNER JOIN	Planing.ColorVariantStatus cvs
				ON	cvs.cvs_id = spcv.cvs_id
				ON	spcv.spcv_id = v.spcv_id   
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		UPDATE	Planing.SketchPlanColorVariant
		SET 	cvs_id = @cv_status_pasport_review,
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
		WHERE	spcv_id = @spcv_id
				AND	cvs_id IN (@cv_status_ready, @cv_status_sel_pasp)
		
		IF @@ROWCOUNT = 0
		BEGIN
		    RAISERROR('Статус не позволяет перехода.', 16, 1)
		    RETURN
		END
		
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
		SELECT	@spcv_id,
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
		WHERE	NOT EXISTS (
		     		SELECT	1
		     		FROM	Planing.SketchPlanColorVariantCompleting spcvc
		     		WHERE	spcvc.spcv_id = @spcv_id
		     				AND	spcvc.completing_id = 32
		     				AND	spcvc.completing_number = 1
		     	)
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