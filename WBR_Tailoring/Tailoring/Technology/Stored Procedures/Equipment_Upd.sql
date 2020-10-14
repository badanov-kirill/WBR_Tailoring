CREATE PROCEDURE [Technology].[Equipment_Upd]
	@equipment_id INT,
	@equipment_name VARCHAR(50),
	@employee_id INT,
	@is_deleted BIT
AS
	SET NOCOUNT ON
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	
	SELECT	@error_text = CASE 
	      	                   WHEN e.equipment_id IS NULL THEN 'Элемента с кодом ' + CAST(v.equipment_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN oa.equipment_id IS NOT NULL THEN 'Элемент с наименованием ' + @equipment_name + ' уже существует под кодом ' + CAST(oa.equipment_id AS VARCHAR(10))
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@equipment_id))v(equipment_id)   
			LEFT JOIN	Technology.Equipment e
				ON	e.equipment_id = v.equipment_id   
			OUTER APPLY (
			      	SELECT	TOP(1) e2.equipment_id
			      	FROM	Technology.Equipment e2
			      	WHERE	e2.equipment_id != e.equipment_id
			      			AND	e2.is_deleted = 0
			      			AND	e2.equipment_name = @equipment_name
			      ) oa
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		UPDATE	Technology.Equipment
		SET 	equipment_name     = @equipment_name,
				dt                 = @dt,
				employee_id        = @employee_id,
				is_deleted         = @is_deleted
		WHERE	equipment_id       = @equipment_id
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