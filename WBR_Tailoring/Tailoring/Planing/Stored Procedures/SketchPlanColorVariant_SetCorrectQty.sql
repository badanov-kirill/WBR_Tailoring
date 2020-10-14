CREATE PROCEDURE [Planing].[SketchPlanColorVariant_SetCorrectQty]
	@spcv_id INT,
	@qty SMALLINT,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @cv_status_ready TINYINT = 2 --Цветовариант готов к отшиву
	DECLARE @cv_status_sel_pasp_ready TINYINT = 4 --Подготовлены паспорта материалов
	DECLARE @cv_status_corr_reserv TINYINT = 5 --На изменение резервов
	DECLARE @cv_status_pasp_get TINYINT = 6 --Паспорта получены
	DECLARE @cv_status_to_layout TINYINT = 7 --Отправлен на раскладку
	DECLARE @cv_status_layout_close TINYINT = 8 --Раскладка привязана
	DECLARE @cv_status_add_as_compain TINYINT = 11 --Создан как компаньен
	DECLARE @ts_tab TABLE (ts_id INT, cnt SMALLINT)
	DECLARE @cnt_ts SMALLINT
	DECLARE @sum_ts_cnt SMALLINT
	DECLARE @bvts_id INT
	DECLARE @pan_id INT
	DECLARE @proc_id INT

	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID
	
	SELECT	@error_text = CASE 
	      	                   WHEN spcv.spcv_id IS NULL THEN 'Цветоварианта с кодом ' + CAST(v.spcv_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN spcv.cvs_id NOT IN (@cv_status_ready, @cv_status_sel_pasp_ready, @cv_status_corr_reserv, @cv_status_pasp_get, @cv_status_to_layout, 
	      	                                           @cv_status_layout_close, @cv_status_add_as_compain) THEN 'У текущей позиции ' + cvs.cvs_name +
	      	                        ', операция запрещена.'
	      	                   WHEN spcv.pan_id IS NULL AND @qty > 0 THEN 'Цветовариант не связан с артикулом сайта'
	      	                   WHEN ISNULL(oa_ts.cnt_ts, 0) = 0 AND @qty > 0 THEN 'У связанного артикула нет ни одного размера'
	      	                   ELSE NULL
	      	              END,
			@pan_id         = spcv.pan_id,
			@cnt_ts         = oa_ts.cnt_ts,
			@sum_ts_cnt     = oa_bvtd.sum_ts_cnt,
			@bvts_id        = bvt.bvts_id
	FROM	(VALUES(@spcv_id))v(spcv_id)   
			LEFT JOIN	Planing.SketchPlanColorVariant spcv   
			INNER JOIN	Planing.ColorVariantStatus cvs
				ON	cvs.cvs_id = spcv.cvs_id
				ON	spcv.spcv_id = v.spcv_id   
			LEFT JOIN	Products.ProdArticleNomenclature pan   
			INNER JOIN	Products.ProdArticle pa
				ON	pa.pa_id = pan.pa_id
				ON	pan.pan_id = spcv.pan_id   
			OUTER APPLY (
			      	SELECT	MAX(ts.ts_name) max_ts_name,
			      			MIN(ts.ts_name) min_ts_name,
			      			COUNT(ts.ts_id) cnt_ts
			      	FROM	Products.ProdArticleNomenclatureTechSize pants   
			      			INNER JOIN	Products.TechSize ts
			      				ON	ts.ts_id = pants.ts_id
			      	WHERE	pants.pan_id = spcv.pan_id
			      	AND pants.is_deleted = 0
			      ) oa_ts
	LEFT JOIN	Settings.BrandVarianTS bvt
				ON	bvt.brand_id = pa.brand_id
				AND	bvt.max_ts_name = oa_ts.max_ts_name
				AND	bvt.min_ts_name = oa_ts.min_ts_name
				AND	bvt.cnt_ts = oa_ts.cnt_ts   
			OUTER APPLY (
			      	SELECT	SUM(bvtd.cnt) sum_ts_cnt
			      	FROM	Settings.BrandVarianTSDetail bvtd
			      	WHERE	bvtd.bvts_id = bvt.bvts_id
			      ) oa_bvtd
	
	
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	INSERT INTO @ts_tab
	  (
	    ts_id,
	    cnt
	  )
	SELECT	pants.ts_id,
			@qty * ISNULL(bvt.cnt, 1) / ISNULL(@sum_ts_cnt, @cnt_ts)
	FROM	Products.ProdArticleNomenclatureTechSize pants   
			LEFT JOIN	Settings.BrandVarianTSDetail bvt
				ON	bvt.ts_id = pants.ts_id
				AND	bvt.bvts_id = @bvts_id
	WHERE	pants.pan_id = @pan_id
	AND pants.is_deleted = 0
	
	BEGIN TRY
		BEGIN TRANSACTION
		UPDATE	Planing.SketchPlanColorVariant
		SET 	corrected_qty     = @qty,
				dt                = @dt,
				employee_id       = @employee_id
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
		WHERE	spcv_id           = @spcv_id
		
		;
		WITH cte_target AS (
			SELECT	spcvt.spcvts_id,
					spcvt.spcv_id,
					spcvt.ts_id,
					spcvt.cnt,
					spcvt.dt,
					spcvt.employee_id
			FROM	Planing.SketchPlanColorVariantTS spcvt
			WHERE	spcvt.spcv_id = @spcv_id
		)
		MERGE cte_target t
		USING @ts_tab s
				ON s.ts_id = t.ts_id
		WHEN MATCHED THEN 
		     UPDATE	
		     SET 	cnt             = s.cnt,
		     		employee_id     = @employee_id,
		     		dt              = @dt
		WHEN NOT MATCHED BY TARGET THEN 
		     INSERT
		     	(
		     		spcv_id,
		     		ts_id,
		     		cnt,
		     		dt,
		     		employee_id
		     	)
		     VALUES
		     	(
		     		@spcv_id,
		     		s.ts_id,
		     		s.cnt,
		     		@dt,
		     		@employee_id
		     	)
		WHEN NOT MATCHED BY SOURCE THEN 
		     DELETE	;
		
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