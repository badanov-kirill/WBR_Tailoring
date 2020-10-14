CREATE PROCEDURE [Documents].[DocumentType_Set]
	@doc_type_id TINYINT,
	@doc_type_name VARCHAR(50),
	@employee_id INT
AS
	SET NOCOUNT ON
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	
	IF EXISTS (
	   	SELECT	1
	   	FROM	Documents.DocumentType dt
	   	WHERE	dt.doc_type_name = @doc_type_name
	   			AND	dt.doc_type_id != @doc_type_id
	   )
	BEGIN
	    RAISERROR('Такое наименование уже используется', 16, 1)
	    RETURN
	END
	
	BEGIN TRY
		;
		MERGE Documents.DocumentType t
		USING (
		      	SELECT	@doc_type_id       doc_type_id,
		      			@doc_type_name     doc_type_name
		      ) s
				ON s.doc_type_id = t.doc_type_id
		WHEN  MATCHED  THEN 
		     UPDATE	
		     SET 	doc_type_name     = s.doc_type_name
		WHEN NOT MATCHED  THEN 
		     INSERT
		     	(
		     		doc_type_id,
		     		doc_type_name
		     	)
		     VALUES
		     	(
		     		s.doc_type_id,
		     		s.doc_type_name
		     	)
		     OUTPUT	INSERTED.doc_type_id,
		     		INSERTED.doc_type_name,
		     		@dt,
		     		@employee_id
		     INTO	History.DocumentType (
		     		doc_type_id,
		     		doc_type_name,
		     		dt,
		     		employee_id
		     	);
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