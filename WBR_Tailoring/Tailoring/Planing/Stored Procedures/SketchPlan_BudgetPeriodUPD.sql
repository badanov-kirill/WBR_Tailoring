CREATE PROCEDURE [Planing].[SketchPlan_BudgetPeriodUPD]
	@sp_id INT,
	@employee_id INT,
	@plan_year SMALLINT,
	@plan_month TINYINT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON	
	
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	
	IF @plan_month < 1
	   OR @plan_month > 12
	BEGIN
	    RAISERROR('Некорректный месяц %d', 16, 1, @plan_month)
	    RETURN
	END
	
	IF @plan_year < 2015
	BEGIN
	    RAISERROR('Некорректный год %d', 16, 1, @plan_year)
	    RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN sp.sp_id IS NULL THEN 'Строчки плана с кодом ' + CAST(v.sp_id AS VARCHAR(10)) + ' не существует'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@sp_id))v(sp_id)   
			LEFT JOIN	Planing.SketchPlan sp
				ON	sp.sp_id = v.sp_id   
	
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		UPDATE	Planing.SketchPlan
		SET 	plan_year       = @plan_year,
				plan_month      = @plan_month,
				dt              = @dt,
				employee_id     = @employee_id
				OUTPUT	INSERTED.sp_id,
						INSERTED.sketch_id,
						INSERTED.ps_id,
						INSERTED.employee_id,
						INSERTED.dt,
						'Изменение периода бюджета'
				INTO	History.SketchPlan (
						sp_id,
						sketch_id,
						ps_id,
						employee_id,
						dt,
						comment
					)
		WHERE	sp_id = @sp_id
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
	