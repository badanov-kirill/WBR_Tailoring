CREATE PROCEDURE [Salary].[SalaryPeriod_Open]
	@salary_period_year SMALLINT,
	@salary_period_mont TINYINT,
	@employee_id INT
AS
	SET NOCOUNT ON
	
	DECLARE @salary_period_id INT
	DECLARE @error_text VARCHAR(MAX)
	
	SELECT	@error_text = CASE 
	      	                   WHEN sp.salary_period_id IS NULL THEN 'Зарплатный период не существует'
	      	                   WHEN sp.close_period_dt IS NULL THEN 'Зарплатный период не закрыт'
	      	                   ELSE NULL
	      	              END,
			@salary_period_id = sp.salary_period_id
	FROM	Salary.SalaryPeriod sp
	WHERE	sp.salary_year = @salary_period_year
			AND	sp.salary_month = @salary_period_mont
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		UPDATE	Salary.SalaryPeriod
		SET 	close_period_dt              = NULL,
				close_period_employee_id     = @employee_id
		WHERE	salary_period_id             = @salary_period_id
				AND	close_period_dt IS NOT NULL
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