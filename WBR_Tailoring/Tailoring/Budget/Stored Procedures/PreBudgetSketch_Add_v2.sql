CREATE PROCEDURE [Budget].[PreBudgetSketch_Add_v2]
	@sketch_id INT,
	@plan_year SMALLINT,
	@plan_month TINYINT,
	@employee_id INT
AS
	SET NOCOUNT ON
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	
	IF @plan_month < 1
	   OR @plan_month > 12
	BEGIN
	    RAISERROR('Некорректный месяц %d', 16, 1, @plan_month)
	    RETURN
	END
	
	IF @plan_year < (YEAR(@dt) - 1)
	   OR @plan_year > (YEAR(@dt) + 1)
	BEGIN
	    RAISERROR('Некорректный год %d', 16, 1, @plan_year)
	    RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN s.sketch_id IS NULL THEN 'Артикула с кодом ' + CAST(s.sketch_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN s.is_deleted = 1 THEN 'Эскиз этого артикула помечен на удаление'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@sketch_id))v(sketch_id)      
			LEFT JOIN	Products.Sketch s
				ON	s.sketch_id = v.sketch_id

	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN pbs.pbs_id IS NOT NULL THEN 'Этот артикул уже запланирован на этот месяц сотрудником с кодом ' + CAST(pbs.planing_employee_id AS VARCHAR(10))
	      	                   ELSE NULL
	      	              END
	FROM	Budget.PreBudgetSketch pbs
	WHERE	pbs.sketch_id = @sketch_id
			AND	pbs.plan_year = @plan_year
			AND	pbs.plan_month = @plan_month
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		INSERT INTO Budget.PreBudgetSketch
			(
				sketch_id,
				plan_year,
				plan_month,
				planing_employee_id,
				planing_dt,
				employee_id,
				dt
			)
		VALUES
			(
				@sketch_id,
				@plan_year,
				@plan_month,
				@employee_id,
				@dt,
				@employee_id,
				@dt
			)
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