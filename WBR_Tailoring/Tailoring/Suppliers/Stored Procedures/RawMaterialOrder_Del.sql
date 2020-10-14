CREATE PROCEDURE [Suppliers].[RawMaterialOrder_Del]
	@rmo_id INT,
	@employee_id INT,
	@comment VARCHAR(200) = NULL
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @rmod_status_ordered TINYINT = 1 -- заказан у поставщика
	DECLARE @rmod_status_deleted TINYINT = 2 -- удален
	
	DECLARE @cvc_state_need_proc TINYINT = 1
	DECLARE @cvc_state_order_sup TINYINT = 2
	DECLARE @cvc_state_covered_wh TINYINT = 3
	
	DECLARE @status_bayer_repeat TINYINT = 7
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @sketch_plan_tab TABLE(sp_id INT)
	DECLARE @proc_id INT

	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID
	
	SELECT	@error_text = CASE 
	      	                   WHEN rmo.rmo_id IS NULL THEN 'Заказа поставщику с номером ' + CAST(v.rmo_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN oadr.is_modify IS NOT NULL OR oad.is_modify IS NOT NULL THEN 'Детали заказа уже разнесены по шк, удалять нельзя'
	      	                   WHEN rmo.is_deleted = 1 THEN 'Документ уже удален'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@rmo_id))v(rmo_id)   
			LEFT JOIN	Suppliers.RawMaterialOrder rmo
				ON	rmo.rmo_id = v.rmo_id   
			OUTER APPLY (
			      	SELECT	TOP(1) 1 is_modify
			      	FROM	Suppliers.RawMaterialOrderDetailFromReserv rmodfr
			      	WHERE	rmodfr.rmo_id = rmo.rmo_id
			      			AND	rmodfr.rmods_id != @rmod_status_ordered
			      )oadr
	OUTER APPLY (
	      	SELECT	TOP(1) 1 is_modify
	      	FROM	Suppliers.RawMaterialOrderDetail rmod
	      	WHERE	rmod.rmo_id = rmo.rmo_id
	      			AND	rmod.rmods_id != @rmod_status_ordered
	      ) oad
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	INSERT INTO @sketch_plan_tab
	  (
	    sp_id
	  )
	SELECT	DISTINCT spcv.sp_id
	FROM	Suppliers.RawMaterialOrderDetailFromReserv rmodfr   
			INNER JOIN	Suppliers.RawMaterialStockReserv rmsr
				ON	rmsr.rmsr_id = rmodfr.rmsr_id   
			INNER JOIN	Planing.SketchPlanColorVariantCompleting spcvc
				ON	spcvc.spcvc_id = rmsr.spcvc_id   
			INNER JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.spcv_id = spcvc.spcv_id
	WHERE	rmodfr.rmo_id = @rmo_id
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		UPDATE	Suppliers.RawMaterialOrder
		SET 	is_deleted      = 1,
				comment         = ISNULL(@comment, comment),
				employee_id     = @employee_id,
				dt              = @dt
		WHERE	rmo_id          = @rmo_id
		
		UPDATE	Suppliers.RawMaterialOrderDetailFromReserv
		SET 	rmods_id = @rmod_status_deleted
		WHERE	rmo_id = @rmo_id
		
		UPDATE	Suppliers.RawMaterialOrderDetail
		SET 	rmods_id = @rmod_status_deleted
		WHERE	rmo_id = @rmo_id
		
		UPDATE	spcvc
		SET 	cs_id           = CASE 
		    	             WHEN cs_id = @cvc_state_order_sup THEN @cvc_state_need_proc
		    	             ELSE cs_id
		    	        END,
				dt              = @dt,
				employee_id     = @employee_id
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
		FROM	Suppliers.RawMaterialOrderDetailFromReserv rmodfr
				INNER JOIN	Suppliers.RawMaterialStockReserv rmsr
					ON	rmsr.rmsr_id = rmodfr.rmsr_id
				INNER JOIN	Planing.SketchPlanColorVariantCompleting spcvc
					ON	spcvc.spcvc_id = rmsr.spcvc_id
		WHERE	rmodfr.rmo_id = @rmo_id
		
		UPDATE	sp
		SET 	ps_id = @status_bayer_repeat,
				employee_id = @employee_id,
				dt = @dt
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
				INNER JOIN	@sketch_plan_tab spt
					ON	spt.sp_id = sp.sp_id
		WHERE	EXISTS (
		     		SELECT	1
		     		FROM	Planing.SketchPlanColorVariant spcv   
		     				INNER JOIN	Planing.SketchPlanColorVariantCompleting spcvc
		     					ON	spcvc.spcv_id = spcv.spcv_id
		     		WHERE	spcv.sp_id = sp.sp_id
		     				AND	spcvc.cs_id NOT IN (@cvc_state_order_sup, @cvc_state_covered_wh)
		     				AND spcv.is_deleted = 0
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
