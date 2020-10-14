CREATE PROCEDURE [Suppliers].[RawMaterialOrderDetailFromReserv_Del]
	@rmodr_id INT,
	@employee_id INT
AS
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @rmod_status_ordered TINYINT = 1 -- заказан у поставщика
	DECLARE @rmod_status_deleted TINYINT = 2 -- удален
	
	DECLARE @cvc_state_create TINYINT = 1
	
	DECLARE @status_bayer_repeat TINYINT = 7
	DECLARE @status_processed_bayer TINYINT = 8
	DECLARE @status_complite TINYINT = 4
	
	DECLARE @spcvc_id INT
	DECLARE @sp_id INT
	DECLARE @proc_id INT

	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID
	
	SELECT	@error_text = CASE 
	      	                   WHEN rmodfr.rmodr_id IS NULL THEN 'Строчки документа с кодом ' + CAST(v.rmodr_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN oar.doc_id IS NOT NULL THEN 'Эта позиция распределена в поступлении ' + CAST(oar.doc_id AS VARCHAR(10))
	      	                   ELSE NULL
	      	              END,
			@spcvc_id     = rmsr.spcvc_id,
			@sp_id        = spcv.sp_id
	FROM	(VALUES(@rmodr_id))v(rmodr_id)   
			LEFT JOIN	Suppliers.RawMaterialOrderDetailFromReserv rmodfr   
			INNER JOIN	Suppliers.RawMaterialOrderDetailStatus rmods
				ON	rmods.rmods_id = rmodfr.rmods_id   
			INNER JOIN	Suppliers.RawMaterialStockReserv rmsr
				ON	rmsr.rmsr_id = rmodfr.rmsr_id   
			INNER JOIN	Planing.SketchPlanColorVariantCompleting spcvc
				ON	spcvc.spcvc_id = rmsr.spcvc_id   
			INNER JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.spcv_id = spcvc.spcv_id
				ON	rmodfr.rmodr_id = v.rmodr_id
			OUTER APPLY (
			      	SELECT	TOP(1) rmiorrd.doc_id
			      	FROM	Material.RawMaterialIncomeOrderReservRelationDetail rmiorrd
			      	WHERE	rmiorrd.rmodr_id = rmodfr.rmodr_id
			      	ORDER BY rmiorrd.rmid_id DESC
			      ) oar
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		UPDATE	Suppliers.RawMaterialOrderDetailFromReserv
		SET 	rmods_id = @rmod_status_deleted,
				employee_id = @employee_id,
				dt = @dt
		WHERE	rmodr_id = @rmodr_id
				AND	rmods_id = @rmod_status_ordered
		
		UPDATE	Planing.SketchPlanColorVariantCompleting
		SET 	cs_id = @cvc_state_create,
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
		WHERE	spcvc_id = @spcvc_id
		
		UPDATE	Planing.SketchPlan
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
		WHERE	sp_id = @sp_id
				AND	ps_id != @status_bayer_repeat
		
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