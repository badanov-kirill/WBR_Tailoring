CREATE PROCEDURE [Planing].[SketchPlan_BayerToDesigner]
	@sp_id INT,
	@employee_id INT,
	@comment VARCHAR(200) = NULL
AS
	SET NOCOUNT ON 
	SET XACT_ABORT ON
	
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	
	DECLARE @cvc_state_create TINYINT = 1
	DECLARE @status_bayer TINYINT = 5
	DECLARE @status_bayer_to_designer TINYINT = 6
	DECLARE @status_bayer_repeat TINYINT = 7
	DECLARE @cv_status_create TINYINT = 1 --Создан
	DECLARE @status_processed_bayer TINYINT = 8
	DECLARE @proc_id INT

	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID
	
	SELECT	@error_text = CASE 
	      	                   WHEN sp.sp_id IS NULL THEN 'Плана с номером ' + CAST(v.sp_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN sp.ps_id = @status_bayer_to_designer THEN 'Этот эскиз уже отклонен'
	      	                   WHEN sp.ps_id NOT IN (@status_bayer, @status_bayer_repeat, @status_processed_bayer) THEN 'Эскиз находится в статусе ' + ps.ps_name +
	      	                        ' отправлять дизайнеру нельзя.'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@sp_id))v(sp_id)   
			LEFT JOIN	Planing.SketchPlan sp   
			INNER JOIN	Planing.PlanStatus ps
				ON	ps.ps_id = sp.ps_id
				ON	sp.sp_id = v.sp_id   
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION 
		
		UPDATE	Planing.SketchPlan
		SET 	ps_id = @status_bayer_to_designer,
				employee_id = @employee_id,
				dt = @dt,
				comment = ISNULL(@comment, comment)
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
				AND	ps_id IN (@status_bayer, @status_bayer_repeat, @status_processed_bayer)
		
		IF @@ROWCOUNT = 0
		BEGIN
		    RAISERROR('Перечитайте данные, статус уже изменен.', 16, 1)
		    RETURN
		END
		
		DELETE	r
		FROM	Suppliers.RawMaterialStockReserv r   
				INNER JOIN	Planing.SketchPlanColorVariantCompleting spcvc
					ON	spcvc.spcvc_id = r.spcvc_id   
				INNER JOIN	Planing.SketchPlanColorVariant spcv
					ON	spcv.spcv_id = spcvc.spcv_id   
				INNER JOIN	Planing.SketchPlan sp
					ON	sp.sp_id = spcv.sp_id
		WHERE	sp.sp_id = @sp_id
				AND	NOT EXISTS (
				   		SELECT	1
				   		FROM	Suppliers.RawMaterialOrderDetailFromReserv rmodfr
				   		WHERE	rmodfr.rmsr_id = r.rmsr_id
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