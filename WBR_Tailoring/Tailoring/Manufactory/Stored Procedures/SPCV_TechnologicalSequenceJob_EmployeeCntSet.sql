CREATE PROCEDURE [Manufactory].[SPCV_TechnologicalSequenceJob_EmployeeCntSet]
	@data_xml XML,
	@employee_id INT
AS
	SET NOCOUNT ON
	DECLARE @data_tab TABLE (stsj_id INT, employee_cnt SMALLINT)
	DECLARE @error_text VARCHAR(MAX)
	
	INSERT INTO @data_tab
		(
			stsj_id,
			employee_cnt
		)
	SELECT	ml.value('@stsj[1]', 'int'),
			ml.value('@cnt[1]', 'smallint')
	FROM	@data_xml.nodes('root/det')x(ml)
	
	SELECT	@error_text = CASE 
	      	                   WHEN stsj.stsj_id IS NULL THEN 'Работы с кодом ' + CAST(dt.stsj_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN stsj.employee_cnt IS NOT NULL THEN 'Работа с кодом ' + CAST(dt.stsj_id AS VARCHAR(10)) + ' уже подтверждена в количестве ' +
	      	                        CAST(stsj.employee_cnt AS VARCHAR(10))
	      	                   WHEN stsj.job_employee_id != @employee_id THEN 'Работы другого сотрудника подтверждать нельзя.'
	      	                   WHEN stsj.plan_cnt < dt.employee_cnt THEN 'Нельзя указывать выполненных операций больше чем назначено.'
	      	                   ELSE NULL
	      	              END
	FROM	@data_tab dt   
			LEFT JOIN	Manufactory.SPCV_TechnologicalSequenceJob stsj
				ON	stsj.stsj_id = dt.stsj_id
	WHERE	stsj.stsj_id IS NULL
			OR  stsj.employee_cnt IS NOT NULL
			OR	stsj.job_employee_id != @employee_id
			OR  stsj.plan_cnt < dt.employee_cnt
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		UPDATE	stsj
		SET 	employee_cnt = dt.employee_cnt
		FROM	Manufactory.SPCV_TechnologicalSequenceJob stsj
				INNER JOIN	@data_tab dt
					ON	dt.stsj_id = stsj.stsj_id
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