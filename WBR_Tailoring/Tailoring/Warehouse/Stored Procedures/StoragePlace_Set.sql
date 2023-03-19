CREATE PROCEDURE [Warehouse].[StoragePlace_Set]
	@storageplaces Warehouse.StoragePlaces READONLY,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @storageplace_output TABLE (
	        	place_id INT NOT NULL,
	        	place_name VARCHAR(50) NOT NULL,
	        	stage INT NULL,
	        	street INT NULL,
	        	section INT NULL,
	        	rack INT NULL,
	        	field INT NULL,
	        	creator_employee_id INT NOT NULL,
	        	create_dt dbo.SECONDSTIME NOT NULL,
	        	employee_id INT NOT NULL,
	        	dt dbo.SECONDSTIME NOT NULL,
	        	is_deleted BIT NOT NULL,
	        	place_type_id INT NOT NULL,
	        	zor_id INT NOT NULL
	        )
	
	SELECT	@error_text = CASE 
	      	                   WHEN sp.place_id IS NOT NULL AND sp1.place_id IS NULL THEN 'Места с кодом ' + CAST(sp.place_id AS VARCHAR(10)) +
	      	                        ' не существует, нельзя обновить по нему данные'
	      	                   WHEN spt.place_type_id IS NULL THEN 'Типа места с кодом ' + CAST(sp.place_type_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN zor.zor_id IS NULL THEN 'Зоны ответственности с кодом ' + CAST(sp.zor_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN oa.place_id IS NOT NULL THEN 'Наименование ' + sp.place_name + ' уже используется в этом офисе у места с кодом ' + CAST(oa.place_id AS VARCHAR(10))
	      	                   WHEN oaс.cnt > 1 THEN 'Наименование ' + sp.place_name + ' использовано более одного раза'
	      	                   ELSE NULL
	      	              END
	FROM	@storageplaces sp   
			LEFT JOIN	Warehouse.StoragePlaceType spt
				ON	spt.place_type_id = sp.place_type_id   
			LEFT JOIN	Warehouse.ZoneOfResponse zor
				ON	zor.zor_id = sp.zor_id   
			LEFT JOIN	Warehouse.StoragePlace sp1
				ON	sp1.place_id = sp.place_id   
			OUTER APPLY (
			      	SELECT	sp2.place_id
			      	FROM	Warehouse.StoragePlace sp2
			      	WHERE	sp2.place_name = sp.place_name
			      			AND	(sp2.place_id != sp.place_id OR sp.place_id IS NULL)
			      			AND	ISNULL(sp2.zor_id, 0) = ISNULL(sp.zor_id, 0)
			      			AND	sp2.is_deleted = 0
			      			AND	sp.is_deleted = 0
			      ) oa
	OUTER APPLY (
	      	SELECT	COUNT(*)           cnt
	      	FROM	@storageplaces     sp3
	      	WHERE	sp3.place_name = sp.place_name
	      			AND	ISNULL(sp3.zor_id, 0) = ISNULL(sp.zor_id, 0)
	      ) oaс
	WHERE	(sp.place_id IS NOT NULL AND sp1.place_id IS NULL)
			OR	spt.place_type_id IS NULL
			OR	zor.zor_id IS NULL
			OR	oa.place_id IS NOT NULL
			OR	oaс.cnt > 1 
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END	
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		MERGE Warehouse.StoragePlace t
		USING @storageplaces s
				ON t.place_id = s.place_id
		WHEN MATCHED THEN 
		     UPDATE	
		     SET 	t.place_name = s.place_name,
		     		t.stage = s.stage,
		     		t.street = s.street,
		     		t.section = s.section,
		     		t.rack = s.rack,
		     		t.field = s.field,
		     		t.employee_id = @employee_id,
		     		t.dt = @dt,
		     		t.is_deleted = s.is_deleted,
		     		t.place_type_id = s.place_type_id,
		     		t.zor_id = s.zor_id
		WHEN NOT MATCHED THEN 
		     INSERT
		     	(
		     		place_name,
		     		stage,
		     		street,
		     		section,
		     		rack,
		     		field,
		     		creator_employee_id,
		     		create_dt,
		     		employee_id,
		     		dt,
		     		is_deleted,
		     		place_type_id,
		     		zor_id
		     	)
		     VALUES
		     	(
		     		s.place_name,
		     		s.stage,
		     		s.street,
		     		s.section,
		     		s.rack,
		     		s.field,
		     		@employee_id,
		     		@dt,
		     		@employee_id,
		     		@dt,
		     		s.is_deleted,
		     		s.place_type_id,
		     		s.zor_id
		     	)
		     OUTPUT	INSERTED.place_id,
		     		INSERTED.place_name,
		     		INSERTED.stage,
		     		INSERTED.street,
		     		INSERTED.section,
		     		INSERTED.rack,
		     		INSERTED.field,
		     		INSERTED.creator_employee_id,
		     		INSERTED.create_dt,
		     		INSERTED.employee_id,
		     		INSERTED.dt,
		     		INSERTED.is_deleted,
		     		INSERTED.place_type_id,
		     		INSERTED.zor_id
		     INTO	@storageplace_output (
		     		place_id,
		     		place_name,
		     		stage,
		     		street,
		     		section,
		     		rack,
		     		field,
		     		creator_employee_id,
		     		create_dt,
		     		employee_id,
		     		dt,
		     		is_deleted,
		     		place_type_id,
		     		zor_id
		     	);
		
		INSERT INTO History.StoragePlace
		  (
		    place_id,
		    place_name,
		    stage,
		    street,
		    section,
		    rack,
		    field,
		    creator_employee_id,
		    create_dt,
		    employee_id,
		    dt,
		    is_deleted,
		    place_type_id,
		    zor_id
		  )
		SELECT	so.place_id,
		      	so.place_name,
				so.stage,
				so.street,
				so.section,
				so.rack,
				so.field,
				so.creator_employee_id,
				so.create_dt,
				so.employee_id,
				so.dt,
				so.is_deleted,
				so.place_type_id,
				so.zor_id
		FROM	@storageplace_output so
		
		SELECT	so.place_id,
				so.place_name
		FROM	@storageplace_output so
		
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
		--WITH LOG;
	END CATCH 