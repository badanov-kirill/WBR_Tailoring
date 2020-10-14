CREATE PROCEDURE [Technology].[TechnologicalPattern_Upd]
	@tp_id INT,
	@ct_id INT,
	@tp_name VARCHAR(50),
	@is_deleted BIT = 0,
	@employee_id INT
AS
	SET NOCOUNT ON
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Material.ClothType ct
	   	WHERE	ct.ct_id = @ct_id
	   )
	BEGIN
	    RAISERROR('Типа ткани с кодом %d не существует', 16, 1, @ct_id)
	    RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN tp.tp_id IS NULL THEN 'Шаблона с кодом ' + CAST(v.tp_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN tp2.tp_id IS NOT NULL AND @is_deleted = 0 THEN 'Шаблон и именем ' + @tp_name + ' уже существует.'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@tp_id))v(tp_id)   
			LEFT JOIN	Technology.TechnologicalPattern tp
				ON	tp.tp_id = v.tp_id   
			LEFT JOIN	Technology.TechnologicalPattern tp2
				ON	tp2.tp_id != tp.tp_id
				AND	tp2.tp_name = @tp_name
				AND	tp2.is_deleted = 0
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		UPDATE	Technology.TechnologicalPattern
		SET 	tp_name         = @tp_name,
				ct_id           = @ct_id,
				is_deleted      = @is_deleted,
				employee_id     = @employee_id,
				dt              = @dt
		WHERE	tp_id           = @tp_id
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