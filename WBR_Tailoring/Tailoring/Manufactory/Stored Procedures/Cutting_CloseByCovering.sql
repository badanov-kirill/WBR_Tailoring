CREATE PROCEDURE [Manufactory].[Cutting_CloseByCovering]
	@covering_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	
	SELECT	@error_text = CASE 
	      	                   WHEN c.covering_id IS NULL THEN 'Выдачи с кодом ' + CAST(v.covering_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN c.cutting_dt IS NOT NULL THEN 'Задание выдачи с кодом ' + CAST(v.covering_id AS VARCHAR(10)) + ' уже закрыта.'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@covering_id))v(covering_id)   
			LEFT JOIN	Planing.Covering c
				ON	c.covering_id = v.covering_id   
	
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION 
		
		UPDATE	c
		SET 	c.closing_employee_id = @employee_id,
				c.closing_dt = @dt
		FROM	Manufactory.Cutting c
				INNER JOIN	Planing.SketchPlanColorVariantTS spcvt
					ON	spcvt.spcvts_id = c.spcvts_id
				INNER JOIN	Planing.SketchPlanColorVariant spcv
					ON	spcv.spcv_id = spcvt.spcv_id
				INNER JOIN	Planing.CoveringDetail cd
					ON	cd.spcv_id = spcv.spcv_id
		WHERE	cd.covering_id = @covering_id
				AND	cd.is_deleted = 0
		
		
		UPDATE	c
		SET 	c.cutting_dt = @dt
		FROM	Planing.Covering c
		WHERE	c.covering_id = @covering_id
				AND	c.cutting_dt IS NULL
		
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
	