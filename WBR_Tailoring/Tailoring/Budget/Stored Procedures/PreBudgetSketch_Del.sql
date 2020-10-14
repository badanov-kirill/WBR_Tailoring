CREATE PROCEDURE [Budget].[PreBudgetSketch_Del]
	@pbs_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	
	
	SELECT	@error_text = CASE 
	      	                   WHEN pbs.pbs_id IS NULL THEN 'предбюджета с кодом ' + CAST(v.pbs_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN pbs.employee_id != @employee_id THEN 'Нельзя удалять чужой бюджет'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@pbs_id))v(pbs_id)   
			LEFT JOIN	Budget.PreBudgetSketch pbs
				ON	pbs.pbs_id = v.pbs_id
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		DELETE	
		FROM	Budget.PreBudgetSketch
		WHERE	pbs_id = @pbs_id
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