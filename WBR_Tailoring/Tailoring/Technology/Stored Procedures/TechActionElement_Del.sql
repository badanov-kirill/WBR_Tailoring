CREATE PROCEDURE [Technology].[TechActionElement_Del]
	@ta_id INT,
	@element_id INT
AS
	SET NOCOUNT ON
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Technology.TechAction ta
	   	WHERE	ta.ta_id = @ta_id
	   			AND	ta.is_deleted = 0
	   )
	BEGIN
	    RAISERROR('Действия с кодом %d не существует', 16, 1, @ta_id)
	    RETURN
	END
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Technology.Element e
	   	WHERE	e.element_id = @element_id
	   			AND	e.is_deleted = 0
	   )
	BEGIN
	    RAISERROR('Элемента с кодом %d не существует', 16, 1, @element_id)
	    RETURN
	END
	
	BEGIN TRY
		DELETE	
		FROM	Technology.TechActionElement
		WHERE	ta_id = @ta_id
				AND	element_id = @element_id
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