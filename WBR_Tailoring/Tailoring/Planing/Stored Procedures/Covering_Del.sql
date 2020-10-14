CREATE PROCEDURE [Planing].[Covering_Del]
	@covering_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	
	DECLARE @cv_status_placing TINYINT = 12 --Назначен в цех
	DECLARE @cv_status_rm_issue TINYINT = 14 --На выдаче материалов
	DECLARE @proc_id INT	
	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Planing.Covering c
	   	WHERE	c.covering_id = @covering_id
	   )
	BEGIN
	    RAISERROR('Выдача с кодом %d не существует', 16, 1, @covering_id)
	END
	
	
	SELECT	@error_text = CASE 
	      	                   WHEN spcv.cvs_id NOT IN (@cv_status_rm_issue, @cv_status_placing) THEN 'Есть цветовариает(ы) в статусе ' + cvs.cvs_name + ' переход запрещен.'
	      	                   ELSE NULL
	      	              END
	FROM	Planing.CoveringDetail cd   
			INNER JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.spcv_id = cd.spcv_id   
			INNER JOIN	Planing.ColorVariantStatus cvs
				ON	cvs.cvs_id = spcv.cvs_id
	WHERE	cd.covering_id = @covering_id
	AND spcv.cvs_id NOT IN (@cv_status_rm_issue, @cv_status_placing)
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	IF EXISTS(
	   	SELECT	1
	   	FROM	Planing.CoveringIssueSHKRm cis
	   	WHERE	cis.covering_id = @covering_id
	   			AND	cis.stor_unit_residues_qty != ISNULL(cis.return_qty, 0)
	   )
	BEGIN
	    RAISERROR('По этой выдаче уже выдавались шк и либо не возвращены, либо возвращены в другом количестве. Удалять нельзя', 16, 1)
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
				INNER JOIN	Planing.CoveringDetail cd
					ON	cd.spcv_id = spcv.spcv_id
		WHERE	cd.covering_id = @covering_id
		
		UPDATE	c
		SET 	employee_id = @employee_id,
				dt = @dt,
				planing_employee_id = NULL,
				planing_dt = NULL
		FROM	Manufactory.Cutting c
				INNER JOIN	Planing.SketchPlanColorVariantTS spcvt
					ON	spcvt.spcvts_id = c.spcvts_id
				INNER JOIN	Planing.SketchPlanColorVariant spcv
					ON	spcv.spcv_id = spcvt.spcv_id
				INNER JOIN	Planing.CoveringDetail cd
					ON	cd.spcv_id = spcv.spcv_id
		WHERE	cd.covering_id = @covering_id	
		
		DELETE	ce
		FROM	Manufactory.CuttingEmployee ce   
				INNER JOIN	Manufactory.Cutting c
					ON	c.cutting_id = ce.cutting_id   
				INNER JOIN	Planing.SketchPlanColorVariantTS spcvt
					ON	spcvt.spcvts_id = c.spcvts_id   
				INNER JOIN	Planing.SketchPlanColorVariant spcv
					ON	spcv.spcv_id = spcvt.spcv_id   
				INNER JOIN	Planing.CoveringDetail cd
					ON	cd.spcv_id = spcv.spcv_id
		WHERE	cd.covering_id = @covering_id	
		
		DELETE	
		FROM	Planing.CoveringReserv
		WHERE	covering_id = @covering_id
		
		DELETE	
		FROM	Planing.CoveringIssueSHKRm
		WHERE	covering_id = @covering_id
				AND	stor_unit_residues_qty = ISNULL(return_qty, 0)
		
		DELETE	
		FROM	Planing.CoveringDetail
		WHERE	covering_id = @covering_id
		
		DELETE	
		FROM	Planing.Covering
		WHERE	covering_id = @covering_id
		
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
	