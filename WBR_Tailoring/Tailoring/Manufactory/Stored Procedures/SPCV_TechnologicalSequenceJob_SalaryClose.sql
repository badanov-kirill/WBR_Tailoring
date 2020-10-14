CREATE PROCEDURE [Manufactory].[SPCV_TechnologicalSequenceJob_SalaryClose]
	@data_xml XML,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @data_tab TABLE (stsj_id INT)
	DECLARE @error_text VARCHAR(MAX)
	
	INSERT INTO @data_tab
		(
			stsj_id
		)
	SELECT	ml.value('@stsj[1]', 'int')
	FROM	@data_xml.nodes('root/det')x(ml)
	
	SELECT	@error_text = CASE 
	      	                   WHEN dt.stsj_id IS NULL THEN 'Некорректный хмл.'
	      	                   WHEN dt.stsj_id IS NOT NULL AND stsj.stsj_id IS NULL THEN 'Задание в работу с кодом ' + CAST(dt.stsj_id AS VARCHAR(10)) +
	      	                        ' не существует.'
	      	                   WHEN stsj.salary_close_dt IS NOT NULL THEN 'Задание в работу с кодом ' + CAST(dt.stsj_id AS VARCHAR(10)) +
	      	                        ' уже закрыто.'
	      	                   WHEN dt.stsj_id IS NOT NULL AND stsj.close_dt IS NULL THEN 'Задание в работу с кодом ' + CAST(dt.stsj_id AS VARCHAR(10)) +
	      	                        ' не подтверждено мастером.'
	      	                   ELSE NULL
	      	              END
	FROM	@data_tab dt   
			LEFT JOIN	Manufactory.SPCV_TechnologicalSequenceJob stsj
				ON	stsj.stsj_id = dt.stsj_id
	WHERE	dt.stsj_id IS NULL
			OR	stsj.stsj_id IS NULL

	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
		
	BEGIN TRY
		
		UPDATE	j
		SET 	j.salary_close_dt = @dt,
				j.salary_close_employee_id = @employee_id
		FROM	Manufactory.SPCV_TechnologicalSequenceJob j				
		WHERE	EXISTS(
		     		SELECT	1
		     		FROM	@data_tab dt
		     		WHERE	dt.stsj_id = j.stsj_id
		     	)
				AND	j.salary_close_dt IS NULL		
		
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
GO	