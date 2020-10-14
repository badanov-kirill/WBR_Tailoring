CREATE PROCEDURE [Technology].[TechnologicalPattern_Add]
	@ct_id INT,
	@tp_name VARCHAR(50),
	@employee_id INT
AS
	SET NOCOUNT ON
	DECLARE @dt DATETIME2(0) = GETDATE()
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Material.ClothType ct
	   	WHERE	ct.ct_id = @ct_id
	   )
	BEGIN
	    RAISERROR('Типа ткани с кодом %d не существует', 16, 1, @ct_id)
	    RETURN
	END
	
	IF EXISTS (
	   	SELECT	1
	   	FROM	Technology.TechnologicalPattern tp
	   	WHERE	tp.tp_name = @tp_name
	   			AND	tp.is_deleted = 0
	   )
	BEGIN
	    IF @tp_name = ''
	    BEGIN
	        RAISERROR('Нельзя создавать шаблон, когда уже есть другой не именованный шаблон.', 16, 1)
	    END
	    ELSE
	    BEGIN
	        RAISERROR('Наименование "%s" уже используется', 16, 1, @tp_name)
	    END; 
	    RETURN
	END
	
	BEGIN TRY
		INSERT INTO Technology.TechnologicalPattern
			(
				tp_name,
				ct_id,
				is_deleted,
				employee_id,
				create_employee_id,
				dt
			)OUTPUT	INSERTED.tp_id
		VALUES
			(
				@tp_name,
				@ct_id,
				0,
				@employee_id,
				@employee_id,
				@dt
			)
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