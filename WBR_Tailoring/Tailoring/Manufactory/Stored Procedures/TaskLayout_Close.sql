CREATE PROCEDURE [Manufactory].[TaskLayout_Close]
	@tl_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @spcv_id INT
	DECLARE @proc_id INT
	
	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID
	
	DECLARE @tl_status_close TINYINT = 2 --Закрыто
	DECLARE @cv_status_to_layout TINYINT = 7 --Отправлен на раскладку
	DECLARE @cv_status_layout_close TINYINT = 8 --Раскладка привязана
	
	SELECT	@error_text = CASE 
	      	                   WHEN tl.tl_id IS NULL THEN 'Задания с номером ' + CAST(v.tl_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN tl.tls_id = @tl_status_close THEN 'Задание уже закрыто.'
	      	                   ELSE NULL
	      	              END,
			@spcv_id = tl.spcv_id
	FROM	(VALUES(@tl_id))v(tl_id)   
			LEFT JOIN	Manufactory.TaskLayout tl
				ON	tl.tl_id = v.tl_id
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION 
		
		UPDATE	Manufactory.TaskLayout
		SET 	tls_id = @tl_status_close,
				dt = @dt,
				employee_id = @employee_id
		WHERE	tl_id = @tl_id
				AND	tls_id != @tl_status_close
		
		IF @@ROWCOUNT = 0
		BEGIN
		    RAISERROR('Задание уже закрыто', 16, 1)
		    RETURN
		END
		
		UPDATE	spcv
		SET 	spcv.cvs_id = @cv_status_layout_close,
				spcv.employee_id = @employee_id,
				spcv.dt = @dt
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
		WHERE	spcv.spcv_id = @spcv_id
				AND	spcv.cvs_id = @cv_status_to_layout
				AND	NOT EXISTS (
				   		SELECT	1
				   		FROM	Manufactory.TaskLayout tl
				   		WHERE	tl.spcv_id = @spcv_id
				   				AND	tl.tls_id != @tl_status_close
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
		
		
		RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess) WITH LOG;
	END CATCH 
				