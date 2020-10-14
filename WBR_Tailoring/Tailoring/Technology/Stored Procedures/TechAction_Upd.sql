CREATE PROCEDURE [Technology].[TechAction_Upd]
	@ta_id INT,
	@ta_name VARCHAR(50),
	@employee_id INT,
	@is_deleted BIT
AS
	SET NOCOUNT ON
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	
	SELECT	@error_text = CASE 
	      	                   WHEN ta.ta_id IS NULL THEN 'Действия с кодом ' + CAST(v.ta_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN oa.ta_id IS NOT NULL THEN 'Действие с наименованием ' + @ta_name + ' уже существует под кодом ' + CAST(oa.ta_id AS VARCHAR(10))
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@ta_id))v(ta_id)   
			LEFT JOIN	Technology.TechAction ta
				ON	ta.ta_id = v.ta_id   
			OUTER APPLY (
			      	SELECT	TOP(1) ta2.ta_id
			      	FROM	Technology.TechAction ta2
			      	WHERE	ta2.ta_id != ta.ta_id
			      			AND	ta2.is_deleted = 0
			      			AND	ta2.ta_name = @ta_name
			      ) oa
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		UPDATE	Technology.TechAction
		SET 	ta_name         = @ta_name,
				dt              = @dt,
				employee_id     = @employee_id,
				is_deleted      = @is_deleted
		WHERE	ta_id           = @ta_id
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