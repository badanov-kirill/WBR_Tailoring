CREATE PROCEDURE [Planing].[SketchPlanColorVariant_Set_plan_delivery]
	@start_dt DATE,
	@finish_dt DATE,
	@employee_id INT,
	@data_xml XML,
	@office_id INT
AS
	SET NOCOUNT ON 
	
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @proc_id INT

	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID
	
	DECLARE @data_tab TABLE (spcv_id INT)
	
	INSERT INTO @data_tab
	  (
	    spcv_id
	  )
	SELECT	ml.value('@spcv', 'int')
	FROM	@data_xml.nodes('root/det')x(ml)
	
	SELECT	@error_text = CASE 
	      	                   WHEN spcv.spcv_id IS NULL THEN 'Цветоварианта с кодом ' + CAST(dt.spcv_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN oa.cnt > 1 THEN 'Цветоварианта с кодом ' + CAST(dt.spcv_id AS VARCHAR(10)) + ' указан более одного раза'
	      	                   ELSE NULL
	      	              END
	FROM	@data_tab dt   
			LEFT JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.spcv_id = dt.spcv_id   
			OUTER APPLY (
			      	SELECT	COUNT(dt2.spcv_id) cnt
			      	FROM	@data_tab dt2
			      	WHERE	dt2.spcv_id = dt.spcv_id
			      ) oa
	WHERE	spcv.spcv_id IS NULL
			OR	oa.cnt > 1
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	IF NOT EXISTS (SELECT 1 FROM Settings.OfficeSetting os WHERE os.office_id = @office_id)
	BEGIN
		RAISERROR('Офиса с кодом %d не существует', 16, 1, @office_id)
	    RETURN
	END
	
	BEGIN TRY
		UPDATE	spcv
		SET 	begin_plan_delivery_dt = @start_dt,
				end_plan_delivery_dt = @finish_dt,
				employee_id = @employee_id,
				dt = @dt,
				sew_office_id = @office_id
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
					ON dt.spcv_id = spcv.spcv_id
		
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