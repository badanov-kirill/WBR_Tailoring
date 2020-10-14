CREATE PROCEDURE [Manufactory].[TaskSew_Close]
	@employee_id INT,
	@xml_data XML
AS
	SET NOCOUNT ON
	
	DECLARE @data_tab TABLE (tss_id INT, stream_time SMALLINT, is_mixed BIT)
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @with_log BIT = 1
	
	INSERT INTO @data_tab
	  (
	    tss_id,
	    stream_time,
	    is_mixed
	  )
	SELECT	ml.value('@id', 'int'),
			ml.value('@st', 'smallint'),
			ml.value('@mix', 'bit')
	FROM	@xml_data.nodes('samples/sample')x(ml)
	
	SELECT	@error_text = CASE 
	      	                   WHEN tss.tss_id IS NULL THEN 'Макета/образца с кодом ' + CAST(dt.tss_id AS VARCHAR(10)) + ' не существует'
	      	                   ELSE NULL
	      	              END
	FROM	@data_tab dt   
			LEFT JOIN	Manufactory.TaskSewSample tss
				ON	tss.tss_id = dt.tss_id
	WHERE	tss.tss_id IS NULL
	
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN v.cnt = 0 THEN 'Не переданы макеты/образцы для задания'
	      	                   WHEN v.cnt != v.cnt_dst THEN 'Переданы макеты/образцы с дублями'
	      	                   ELSE NULL
	      	              END
	FROM	(SELECT	COUNT(dt.tss_id)     cnt,
	    	 		COUNT(DISTINCT dt.tss_id) cnt_dst
	    	 FROM	@data_tab           dt)v	
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		UPDATE	tss
		SET 	stream_time           = dt.stream_time,
				close_employee_id     = @employee_id,
				close_dt              = @dt,
				is_mixed			  = dt.is_mixed
		FROM	Manufactory.TaskSewSample tss
				INNER JOIN	@data_tab dt
					ON	dt.tss_id = tss.tss_id
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