CREATE PROCEDURE [Material].[RawMaterialPostingBuffer_Add]
	@shkrm_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @with_log BIT = 1
	DECLARE @error_text VARCHAR(MAX)
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Warehouse.SHKRawMaterial sm
	   	WHERE	sm.shkrm_id = @shkrm_id
	   )
	BEGIN
	    RAISERROR('ШК материала с кодом %d не существует', 16, 1, @shkrm_id)
	    RETURN
	END
	
	IF EXISTS(
	   	SELECT	1
	   	FROM	Warehouse.SHKRawMaterial sm
	   	WHERE	sm.shkrm_id = @shkrm_id
	   			AND	sm.dt_mapping IS NOT NULL
	   )
	BEGIN
	    RAISERROR('Нельзя использовать шк %d повторно', 16, 1, @shkrm_id)
	    RETURN
	END
	
	SELECT	@error_text = 'Штрихкод ' + CAST(smai.shkrm_id AS VARCHAR(10)) + ' уже оприходован на склад документом ' +
	      	dt.doc_type_name + ' № ' + CAST(smai.doc_id AS VARCHAR(10)) + ' датой ' + CONVERT(VARCHAR(20), smai.dt, 121)
	FROM	Warehouse.SHKRawMaterialActualInfo smai   
			INNER JOIN	Documents.DocumentType dt
				ON	dt.doc_type_id = smai.doc_type_id
	WHERE	smai.shkrm_id = @shkrm_id
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	DELETE	
	FROM	Material.RawMaterialPostingBuffer
	WHERE	DATEDIFF(minute, dt, @dt) > 60
	
	IF EXISTS(
	   	SELECT	1
	   	FROM	Material.RawMaterialPostingBuffer
	   )
	BEGIN
	    RAISERROR('В очереди уже содержится необработанный ШК', 16, 1)
	    RETURN
	END
	
	BEGIN TRY
		INSERT INTO Material.RawMaterialPostingBuffer
		  (
		    shkrm_id,
		    dt,
		    employee_id
		  )
		SELECT	@shkrm_id,
				@dt,
				@employee_id
		WHERE	NOT EXISTS (
		     		SELECT	1
		     		FROM	Material.RawMaterialPostingBuffer
		     	)
		
		IF @@ROWCOUNT = 0
		BEGIN
		    SET @with_log = 0
		    RAISERROR('В очереди уже содержится необработанный ШК', 16, 1)
		    RETURN
		END
		
		
		
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