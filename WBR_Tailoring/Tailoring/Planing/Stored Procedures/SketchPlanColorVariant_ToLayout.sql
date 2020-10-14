CREATE PROCEDURE [Planing].[SketchPlanColorVariant_ToLayout]
	@spcv_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	
	DECLARE @cv_status_corr_reserv TINYINT = 5 --На изменение резервов
	DECLARE @cv_status_layout_close TINYINT = 8 --Раскладка привязана
	DECLARE @cv_status_to_layout TINYINT = 7 --Отправлен на раскладку
	DECLARE @tl_status_create TINYINT = 1 -- Создан
	DECLARE @rc INT = 1
	DECLARE @tab TABLE (frame_width SMALLINT, completing_id INT, completing_number TINYINT)
	DECLARE @tab_res TABLE (frame_width SMALLINT, completing_id INT, completing_number TINYINT, PRIMARY KEY CLUSTERED(completing_id, completing_number, frame_width))
	DECLARE @task_layout_output TABLE(tl_id INT)
	DECLARE @proc_id INT

	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID
	
	SELECT	@error_text = CASE 
	      	                   WHEN spcv.spcv_id IS NULL THEN 'Цветоварианта с кодом ' + CAST(v.spcv_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN spcv.cvs_id NOT IN (@cv_status_corr_reserv, @cv_status_layout_close) THEN 'Статус цветоварианта ' + cvs.cvs_name +
	      	                        ', перевод на раскладку запрещен.'
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
	
	INSERT INTO @tab
	  (
	    frame_width,
	    completing_id,
	    completing_number
	  )
	SELECT	smai.frame_width                frame_width,
			spcvc.completing_id,
			spcvc.completing_number
	FROM	Warehouse.SHKRawMaterialActualInfo smai   
			INNER JOIN	Warehouse.SHKRawMaterialReserv smr
				ON	smr.shkrm_id = smai.shkrm_id   
			INNER JOIN	Planing.SketchPlanColorVariantCompleting spcvc
				ON	spcvc.spcvc_id = smr.spcvc_id   
			INNER JOIN	Material.CompletingIsCloth cic
				ON	cic.completing_id = spcvc.completing_id   
			INNER JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.spcv_id = spcvc.spcv_id
	WHERE	spcv.spcv_id = @spcv_id
			AND	smai.frame_width IS NOT     NULL
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	@tab
	   )
	BEGIN
	    RAISERROR('Некорректные резервы', 16, 1)
	    RETURN
	END
	
	INSERT INTO @tab_res
	  (
	    frame_width,
	    completing_id,
	    completing_number
	  )
	SELECT	MIN(t.frame_width)     frame_width,
			t.completing_id,
			t.completing_number
	FROM	@tab                   t
	GROUP BY
		t.completing_id,
		t.completing_number
	
	
	WHILE @rc > 0
	BEGIN
	    INSERT INTO @tab_res
	      (
	        frame_width,
	        completing_id,
	        completing_number
	      )
	    SELECT	MIN(t.frame_width)     frame_width,
	    		t.completing_id,
	    		t.completing_number
	    FROM	@tab t   
	    		OUTER APPLY (
	    		      	SELECT	MAX(tr.frame_width) frame_width
	    		      	FROM	@tab_res tr
	    		      	WHERE	tr.completing_id = t.completing_id
	    		      			AND	tr.completing_number = t.completing_number
	    		      )                oa
	    WHERE	t.frame_width > oa.frame_width * 1.02
	    GROUP BY
	    	t.completing_id,
	    	t.completing_number
	    HAVING
	    	MIN(t.frame_width) IS NOT NULL
	    
	    SET @rc = @@ROWCOUNT
	END
	
	BEGIN TRY
		BEGIN TRANSACTION 
		
		UPDATE	Planing.SketchPlanColorVariant
		SET 	cvs_id = @cv_status_to_layout,
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
				AND	cvs_id IN (@cv_status_corr_reserv, @cv_status_layout_close)
		
		IF @@ROWCOUNT = 0
		BEGIN
		    RAISERROR('Статус не позволяет перехода.', 16, 1)
		    RETURN
		END
		
		INSERT INTO Manufactory.TaskLayout
		  (
		    create_dt,
		    create_employee_id,
		    dt,
		    employee_id,
		    spcv_id,
		    tls_id
		  )OUTPUT	INSERTED.tl_id
		   INTO	@task_layout_output (
		   		tl_id
		   	)
		VALUES
		  (
		    @dt,
		    @employee_id,
		    @dt,
		    @employee_id,
		    @spcv_id,
		    @tl_status_create
		  )
		
		INSERT INTO Manufactory.TaskLayoutCompletingFrameWidth
		  (
		    tl_id,
		    completing_id,
		    completing_number,
		    frame_width
		  )
		SELECT	tlo.tl_id,
				tr.completing_id,
				tr.completing_number,
				tr.frame_width
		FROM	@tab_res tr   
				CROSS JOIN	@task_layout_output tlo
		
		
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