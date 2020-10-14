CREATE PROCEDURE [Planing].[SketchPlanColorVariantCompleting_CovredWh]
	@spcvc_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @sp_id INT
	DECLARE @proc_id INT
	
	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID
	
	
	DECLARE @cvc_state_order_sup TINYINT = 2
	DECLARE @cvc_state_covered_wh TINYINT = 3
	
	DECLARE @status_processed_bayer TINYINT = 8
	DECLARE @status_complite TINYINT = 4
	
	DECLARE @cv_status_create TINYINT = 1 --Создан
	DECLARE @cv_status_ready TINYINT = 2 --Цветовариант готов к отшиву
	
	SELECT	@error_text = CASE 
	      	                   WHEN spcvc.spcvc_id IS NULL THEN 'Кода потребноcти материала цветоварианта ' + CAST(v.spcvc_id AS VARCHAR(10)) +
	      	                        ' не существует.'
	      	                   WHEN spcvc.cs_id = @cvc_state_covered_wh THEN 'У текущей позиции уже статус - Закрыт складским остатком'
	      	                   ELSE NULL
	      	              END,
			@sp_id = spcv.sp_id
	FROM	(VALUES(@spcvc_id))v(spcvc_id)   
			LEFT JOIN	Planing.SketchPlanColorVariantCompleting spcvc   
			INNER JOIN	Planing.CompletingStatus cs
				ON	cs.cs_id = spcvc.cs_id   
			INNER JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.spcv_id = spcvc.spcv_id
				ON	spcvc.spcvc_id = v.spcvc_id 
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END			
	
	BEGIN TRY
		BEGIN TRANSACTION
		
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