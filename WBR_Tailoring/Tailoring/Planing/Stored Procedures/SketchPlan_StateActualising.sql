CREATE PROCEDURE [Planing].[SketchPlan_StateActualising]
	@sp_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON 
	SET XACT_ABORT ON
	
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @per DECIMAL(5, 2) = 65
	DECLARE @reserv TABLE (spcvc_id INT, reserv_qty DECIMAL(9, 3), need_qty DECIMAL(9, 3))
	DECLARE @cv_status_create TINYINT = 1 --Создан
	DECLARE @cv_status_ready TINYINT = 2 --Цветовариант готов к отшиву	 
	
	DECLARE @status_bayer TINYINT = 5
	DECLARE @status_bayer_repeat TINYINT = 7
	DECLARE @status_complite TINYINT = 4
	
	DECLARE @cvc_state_covered_wh TINYINT = 3
	
	DECLARE @proc_id INT
	
	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID
	
	SELECT	@error_text = CASE 
	      	                   WHEN sp.sp_id IS NULL THEN 'Плана с номером ' + CAST(v.sp_id AS VARCHAR(10)) + ' не существует'	      	                  
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@sp_id))v(sp_id)   
			LEFT JOIN	Planing.SketchPlan sp 			
				ON	sp.sp_id = v.sp_id   

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
	
	BEGIN TRY
	BEGIN TRANSACTION 
				
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
	