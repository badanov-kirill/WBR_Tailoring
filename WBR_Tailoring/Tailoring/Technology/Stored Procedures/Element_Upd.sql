CREATE PROCEDURE [Technology].[Element_Upd]
	@element_id INT,
	@element_name VARCHAR(200),
	@employee_id INT,
	@is_deleted BIT
AS
	SET NOCOUNT ON
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	
	SELECT	@error_text = CASE 
	      	                   WHEN e.element_id IS NULL THEN 'Элемента с кодом ' + CAST(v.element_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN oa.element_id IS NOT NULL THEN 'Элемент с наименованием ' + @element_name + ' уже существует под кодом ' + CAST(oa.element_id AS VARCHAR(10))
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@element_id))v(element_id)   
			LEFT JOIN	Technology.Element e
				ON	e.element_id = v.element_id   
			OUTER APPLY (
			      	SELECT	TOP(1) e2.element_id
			      	FROM	Technology.Element e2
			      	WHERE	e2.element_id != e.element_id
			      			AND	e2.is_deleted = 0
			      			AND	e2.element_name = @element_name
			      ) oa
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		UPDATE	Technology.Element
		SET 	element_name     = @element_name,
				dt               = @dt,
				employee_id      = @employee_id,
				is_deleted       = @is_deleted
		WHERE	element_id       = @element_id
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