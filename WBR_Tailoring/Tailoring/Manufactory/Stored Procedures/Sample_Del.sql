CREATE PROCEDURE [Manufactory].[Sample_Del]
	@sample_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @with_log BIT = 1
	
	SELECT	@error_text = CASE 
	      	                   WHEN s.sample_id IS NULL THEN 'Макета/образца с кодом ' + CAST(v.sample_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN s.is_deleted = 1 THEN 'Макет/образц с кодом ' + CAST(v.sample_id AS VARCHAR(10)) + ' уже помечен на удаление'
	      	                   WHEN s.task_sample_id IS NOT NULL THEN 'Макет/образец с кодом ' + CAST(s.sample_id AS VARCHAR(10)) + ' в задании № ' + CAST(s.task_sample_id AS VARCHAR(10)) 
	      	                        + '. Удалять нельзя.'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@sample_id))v(sample_id)   
			LEFT JOIN	Manufactory.[Sample] s
				ON	s.sample_id = v.sample_id
	
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		UPDATE	s
		SET 	s.is_deleted = 1,
				s.employee_id = @employee_id,
				s.dt = @dt
		FROM	Manufactory.[Sample] s
		WHERE	s.sample_id = @sample_id
				AND	s.task_sample_id IS NULL
		
		IF @@ROWCOUNT = 0
		BEGIN
		    SET @with_log = 0
		    RAISERROR('Перечитайте данные и повторите попытку', 16, 1)
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
		
		IF @with_log = 1
		BEGIN
		    RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess) WITH LOG;
		END
		ELSE
		BEGIN
		    RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess)
		END
	END CATCH 