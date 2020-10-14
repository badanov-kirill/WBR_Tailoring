CREATE PROCEDURE [Material].[RawMaterialType_Set]
	@rmt_id INT = NULL,
	@rmt_pid INT,
	@rmt_name VARCHAR(100),
	@employee_id INT,
	@okei_id INT = NULL,
	@stuff_model_id INT = NULL
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt dbo.SECONDSTIME = GETDATE()	
	DECLARE @rmt_out TABLE (rmt_id INT)
	
	IF @rmt_pid IS NOT NULL
	   AND NOT EXISTS(
	       	SELECT	1
	       	FROM	Material.RawMaterialType rmt
	       	WHERE	rmt.rmt_id = @rmt_pid
	       )
	BEGIN
	    RAISERROR('Родителя с кодом %d не существует', 16, 1, @rmt_pid)
	    RETURN
	END
	
	IF EXISTS(
	   	SELECT	1
	   	FROM	Material.RawMaterialType rmt
	   	WHERE	rmt.rmt_name = @rmt_name
	   			AND	(@rmt_id IS NULL OR rmt.rmt_id != @rmt_id)
	   			AND	(rmt.rmt_pid = @rmt_pid OR (rmt.rmt_pid IS NULL AND @rmt_pid IS NULL))
	   )
	BEGIN
	    RAISERROR('Имя "%s" уже используется', 16, 1, @rmt_name)
	    RETURN
	END
	
	IF @okei_id IS NOT NULL
	   AND NOT EXISTS(
	       	SELECT	1
	       	FROM	Qualifiers.OKEI o
	       	WHERE	o.okei_id = @okei_id
	       )
	BEGIN
	    RAISERROR('Еденицы измерения с кодом %d не существует', 16, 1, @okei_id)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION 
		
		MERGE Material.RawMaterialType t
		USING (
		      	SELECT	@rmt_id          rmt_id,
		      			@rmt_pid         rmt_pid,
		      			@rmt_name        rmt_name,
		      			@employee_id     employee_id,
		      			@dt              dt,
		      			@okei_id         okei_id
		      ) s
				ON t.rmt_id = s.rmt_id
		WHEN MATCHED THEN 
		     UPDATE	
		     SET 	rmt_pid         = s.rmt_pid,
		     		rmt_name        = s.rmt_name,
		     		employee_id     = s.employee_id,
		     		dt              = s.dt
		WHEN NOT MATCHED THEN 
		     INSERT
		     	(
		     		rmt_pid,
		     		rmt_name,
		     		employee_id,
		     		dt,
		     		stor_unit_residues_okei_id
		     	)
		     VALUES
		     	(
		     		s.rmt_pid,
		     		s.rmt_name,
		     		s.employee_id,
		     		s.dt,
		     		s.okei_id
		     	)		
		     OUTPUT	INSERTED.rmt_id
		     INTO	@rmt_out (
		     		rmt_id
		     	);
		
		IF @rmt_id IS NULL
		BEGIN
			SELECT @rmt_id = ro.rmt_id FROM @rmt_out ro
		END
		
		MERGE Material.RawMaterialTypeStuffModel t
		USING (
		      	SELECT	@rmt_id             rmt_id,
		      			@stuff_model_id     stuff_model_id,
		      			@employee_id        employee_id,
		      			@dt                 dt
		      ) s
				ON t.rmt_id = s.rmt_id
		WHEN MATCHED AND s.stuff_model_id IS NOT NULL AND t.stuff_model_id != s.stuff_model_id THEN 
		     UPDATE	
		     SET 	t.stuff_model_id = s.stuff_model_id
		WHEN NOT MATCHED AND s.stuff_model_id IS NOT NULL THEN 
		     INSERT
		     	(
		     		rmt_id,
		     		stuff_model_id,
		     		employee_id,
		     		dt
		     	)
		     VALUES
		     	(
		     		s.rmt_id,
		     		s.stuff_model_id,
		     		s.employee_id,
		     		s.dt
		     	)
		WHEN MATCHED AND s.stuff_model_id IS NULL THEN 
		     DELETE	;
		     
		     	
		INSERT INTO Material.RawMaterialTypeVariant
			(
				rmt_id,
				art_id,
				frame_width,
				rmt_astra_id
			)
		SELECT	@rmt_id,
				NULL,
				NULL,
				NULL
		WHERE	NOT EXISTS (
		     		SELECT	1
		     		FROM	Material.RawMaterialTypeVariant rmtv
		     		WHERE	rmtv.rmt_id = @rmt_id
		     				AND	rmtv.art_id IS NULL
		     				AND	rmtv.frame_width IS NULL
		     	)
		
		COMMIT TRANSACTION
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
