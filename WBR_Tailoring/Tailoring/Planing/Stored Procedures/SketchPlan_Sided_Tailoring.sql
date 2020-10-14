﻿CREATE PROCEDURE [Planing].[SketchPlan_Sided_Tailoring]
	@sp_id INT,
	@employee_id INT,
	@comment VARCHAR(200) = NULL
AS
	SET NOCOUNT ON 
	
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @error_text VARCHAR(MAX)

	DECLARE @states_approve TINYINT = 2
	DECLARE @status_bayer_to_designer TINYINT = 6
	DECLARE @status_sided_tailoring TINYINT = 9
	
	SELECT	@error_text = CASE 
	      	                   WHEN sp.sp_id IS NULL THEN 'Плана с номером ' + CAST(v.sp_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN sp.ps_id = @status_sided_tailoring THEN 'Этот эскиз уже отправлен на сторонний отшив'
	      	                   WHEN sp.ps_id NOT IN ( @states_approve, @status_bayer_to_designer) THEN 'Эскиз находится в статусе ' + ps.ps_name + 
	      	                        ' утверждать нельзя.'
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
		UPDATE	Planing.SketchPlan
		SET 	ps_id           = @status_sided_tailoring,
				employee_id     = @employee_id,
				dt              = @dt,
				comment         = ISNULL(@comment, comment)
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
				AND	ps_id IN (@states_approve, @status_bayer_to_designer)
				
		IF @@ROWCOUNT = 0
		BEGIN
			RAISERROR('Перечитайте данные, статус уже изменен.',16,1)
			RETURN
		END
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
	