CREATE PROCEDURE [Planing].[SketchPlanColorVariant_SetSewDeadlineDT]
	@sew_deadline_dt DATE,
	@spcv_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON 
	SET XACT_ABORT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @data_tab TABLE (spcv_id INT, is_mapping BIT)
	
	DECLARE @proc_id INT	
	
	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID
	
	INSERT INTO @data_tab
		(
			spcv_id,
			is_mapping
		)
	VALUES
		(
			@spcv_id,
			0
		)
	
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
	      	                   WHEN s.pt_id IS NULL THEN 'У артикула ' + s.sa + ' не указан тип продукта'
	      	                   WHEN spcv.spcv_id IS NOT NULL AND oa_p.ts_id IS NOT NULL THEN 'У артикула ' + s.sa + ' заполнены не все периметры'
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
			AND	(spcv.spcv_id IS NULL OR spcv.pan_id IS NULL OR s.pt_id IS NULL OR oa_p.ts_id IS NOT NULL)
	
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
				sew_deadline_dt = @sew_deadline_dt
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