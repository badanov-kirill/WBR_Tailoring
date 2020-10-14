CREATE PROCEDURE [Manufactory].[TaskLayoutDetail_UnMapping]
	@tld_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	DECLARE @error_text VARCHAR(MAX)
	
	SELECT	@error_text = CASE 
	      	                   WHEN tld.tld_id IS NULL THEN 'Детали задания с номером ' + CAST(v.tld_id AS VARCHAR(10)) + ' не существует.'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@tld_id))v(tld_id)   
			LEFT JOIN	Manufactory.TaskLayoutDetail tld
				ON	tld.tld_id = v.tld_id
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		DELETE	
		FROM	Manufactory.TaskLayoutDetail
		WHERE	tld_id = @tld_id
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