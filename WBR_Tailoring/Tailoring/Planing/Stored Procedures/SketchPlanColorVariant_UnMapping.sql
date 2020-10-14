CREATE PROCEDURE [Planing].[SketchPlanColorVariant_UnMapping]
	@spcv_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @cv_status_ready TINYINT = 2 --Цветовариант готов к отшиву
	DECLARE @cv_status_sel_pasp_ready TINYINT = 4 --Подготовлены паспорта материалов
	DECLARE @cv_status_corr_reserv TINYINT = 5 --На изменение резервов
	DECLARE @cv_status_pasp_get TINYINT = 6 --Паспорта получены
	DECLARE @cv_status_to_layout TINYINT = 7 --Отправлен на раскладку
	DECLARE @cv_status_layout_close TINYINT = 8 --Раскладка привязана
	DECLARE @cv_status_add_as_compain TINYINT = 11 --Создан как компаньен
	DECLARE @proc_id INT

	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID
		
	SELECT	@error_text = CASE 
	      	                   WHEN spcv.spcv_id IS NULL THEN 'Цветоварианта с кодом ' + CAST(v.spcv_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN spcv.cvs_id NOT IN (@cv_status_ready, @cv_status_sel_pasp_ready, @cv_status_corr_reserv, @cv_status_pasp_get, @cv_status_to_layout, 
	      	                                           @cv_status_layout_close, @cv_status_add_as_compain) THEN 'У текущей позиции ' + cvs.cvs_name + 
	      	                        ', операция запрещена.'
	      	                   WHEN spcv.pan_id IS NULL THEN 'Цветовариант ' + spcv.spcv_name + ' Не привязан к артикулу.'
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
	
	BEGIN TRY
		UPDATE	Planing.SketchPlanColorVariant
		SET 	pan_id = NULL,
				dt = @dt,
				employee_id = @employee_id
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