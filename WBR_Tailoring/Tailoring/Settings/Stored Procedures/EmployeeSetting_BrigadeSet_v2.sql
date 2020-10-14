CREATE PROCEDURE [Settings].[EmployeeSetting_BrigadeSet_v2]
	@brigade_id INT,
	@data_xml XML,
	@begin_dt DATE,
	@create_employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @data_tab TABLE (employee_id INT)
	DECLARE @dt DATETIME2(0) = GETDATE()
	
	IF @brigade_id IS NOT NULL
	   AND NOT EXISTS (
	       	SELECT	1
	       	FROM	Settings.Brigade b
	       	WHERE	b.brigade_id = @brigade_id
	       )
	BEGIN
	    RAISERROR('Бригады с кодом %d не существует.', 16, 1, @brigade_id)
	    RETURN
	END
	
	INSERT INTO @data_tab
		(
			employee_id
		)
	SELECT	ml.value('@id[1]', 'int')
	FROM	@data_xml.nodes('root/det')x(ml)
	
	SET @error_text = 'Сотудников с кодами: ' + (
	    	SELECT	ISNULL(CAST(dt.employee_id AS VARCHAR(10)), 'null') + '; '
	    	FROM	@data_tab dt   
	    			LEFT JOIN	Settings.EmployeeSetting es
	    				ON	es.employee_id = dt.employee_id
	    	WHERE	es.employee_id IS NULL
	    	FOR XML	PATH('')
	    ) + ' не существует'
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	IF EXISTS(
	   	SELECT	1
	   	FROM	Salary.SalaryPeriod sp
	   	WHERE	sp.salary_year >= YEAR(@begin_dt)
	   			AND	sp.salary_month >= MONTH(@begin_dt)
	   			AND	sp.close_period_dt IS NOT NULL
	   )
	BEGIN
	    RAISERROR('Нельзя менять бригады в закрытом зарплатном периоде.', 16, 1)
	    RETURN
	END
	
	IF DAY(@begin_dt) != 1
	BEGIN
	    RAISERROR('Не корректная дата начала работы в бригаде.', 16, 1)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION 
		UPDATE	es
		SET 	brigade_id = @brigade_id
		FROM	Settings.EmployeeSetting es
				INNER JOIN	@data_tab dt
					ON	dt.employee_id = es.employee_id
		WHERE	NOT EXISTS (
		     		SELECT	1
		     		FROM	Settings.BrigadeEmployeeDate bed
		     		WHERE	bed.employee_id = es.employee_id
		     				AND	bed.begin_dt > @begin_dt
		     	)
		
		;
		MERGE Settings.BrigadeEmployeeDate t
		USING @data_tab s
				ON s.employee_id = t.employee_id
				AND t.begin_dt = @begin_dt
		WHEN MATCHED THEN 
		     UPDATE	
		     SET 	brigade_id             = @brigade_id,
		     		create_employee_id     = @create_employee_id,
		     		dt                     = @dt
		WHEN NOT MATCHED THEN 
		     INSERT
		     	(
		     		employee_id,
		     		begin_dt,
		     		brigade_id,
		     		create_employee_id,
		     		dt
		     	)
		     VALUES
		     	(
		     		s.employee_id,
		     		@begin_dt,
		     		@brigade_id,
		     		@create_employee_id,
		     		@dt
		     	);
		
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