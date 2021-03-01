CREATE PROCEDURE [Manufactory].[SPCV_TechnologicalSequenceJob_MasterCntSet]
	@data_xml XML,
	@employee_id INT
AS
	SET NOCOUNT ON
	DECLARE @data_tab TABLE (stsj_id INT, close_cnt SMALLINT)
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @dt DATETIME2(0) = GETDATE()
	
	INSERT INTO @data_tab
		(
			stsj_id,
			close_cnt
		)
	SELECT	ml.value('@stsj[1]', 'int'),
			ml.value('@cnt[1]', 'smallint')
	FROM	@data_xml.nodes('root/det')x(ml)
	
	SELECT	@error_text = CASE 
	      	                   WHEN stsj.stsj_id IS NULL THEN 'Работы с кодом ' + CAST(dt.stsj_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN stsj.close_cnt IS NOT NULL THEN 'Работа с кодом ' + CAST(dt.stsj_id AS VARCHAR(10)) + ' уже подтверждена в количестве ' +
	      	                        CAST(stsj.close_cnt AS VARCHAR(10))
	      	                   WHEN stsj.plan_cnt < dt.close_cnt THEN 'Нельзя указывать выполненных операций больше чем назначено.'
	      	                   ELSE NULL
	      	              END
	FROM	@data_tab dt   
			LEFT JOIN	Manufactory.SPCV_TechnologicalSequenceJob stsj
				ON	stsj.stsj_id = dt.stsj_id
	WHERE	stsj.stsj_id IS NULL
			OR	stsj.close_cnt IS NOT NULL
			OR	stsj.plan_cnt < dt.close_cnt
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		UPDATE	stsj
		SET 	close_cnt             = dt.close_cnt,
				close_dt              = @dt,
				close_employee_id     = @employee_id,
				salary_close_dt		  = NULL,
				salary_close_employee_id = NULL
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