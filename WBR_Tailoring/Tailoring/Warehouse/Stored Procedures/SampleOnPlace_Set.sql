CREATE PROCEDURE [Warehouse].[SampleOnPlace_Set]
	@sample_id INT,
	@place_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @proc_id INT
	DECLARE @sa VARCHAR(76)
	DECLARE @subject_name VARCHAR(50)
	DECLARE @art_name VARCHAR(100)
	DECLARE @brand_name VARCHAR(50)
	
	
	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID
	
	SELECT	@error_text = CASE 
	      	                   WHEN s.sample_id IS NULL THEN 'Макета/образца с кодом ' + CAST(v.sample_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN s.is_deleted = 1 THEN 'Макет/образц с кодом ' + CAST(v.sample_id AS VARCHAR(10)) + ' удален'
	      	                   ELSE NULL
	      	              END,
			@sa               = sk.sa,
			@subject_name     = sj.subject_name,
			@art_name         = an.art_name,
			@brand_name       = b.brand_name
	FROM	(VALUES(@sample_id))v(sample_id)   
			LEFT JOIN	Manufactory.[Sample] s   
			INNER JOIN	Products.Sketch sk   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = sk.art_name_id   
			INNER JOIN	Products.Brand b
				ON	b.brand_id = sk.brand_id   
			INNER JOIN	Products.[Subject] sj
				ON	sj.subject_id = sk.subject_id
				ON	sk.sketch_id = s.sketch_id
				ON	s.sample_id = v.sample_id
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN sp.place_id IS NULL THEN 'Места хранения с кодом ' + CAST(v.place_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN sp.is_deleted = 1 THEN 'Место хранения ' + sp.place_name + ' удалено.'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@place_id))v(place_id)   
			LEFT JOIN	Warehouse.StoragePlace sp
				ON	sp.place_id = v.place_id 
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION 
		
		
		
		;
		MERGE Warehouse.SampleOnPlace t
		USING (
		      	SELECT	@sample_id       sample_id,
		      			@place_id        place_id,
		      			@dt              dt,
		      			@employee_id     employee_id
		      ) s
				ON s.sample_id = t.sample_id
		WHEN MATCHED THEN 
		     UPDATE	
		     SET 	sample_id       = s.sample_id,
		     		place_id        = s.place_id,
		     		dt              = s.dt,
		     		employee_id     = s.employee_id
		WHEN NOT MATCHED THEN 
		     INSERT
		     	(
		     		sample_id,
		     		place_id,
		     		dt,
		     		employee_id
		     	)
		     VALUES
		     	(
		     		s.sample_id,
		     		s.place_id,
		     		s.dt,
		     		s.employee_id
		     	) 
		     OUTPUT	INSERTED.sample_id,
		     		INSERTED.place_id,
		     		INSERTED.dt,
		     		INSERTED.employee_id,
		     		@proc_id
		     INTO	History.SampleOnPlace (
		     		sample_id,
		     		place_id,
		     		dt,
		     		employee_id,
		     		proc_id
		     	);
		
		
		COMMIT TRANSACTION
		
		SELECT	@sa               sa,
				@subject_name     subject_name,
				@art_name         art_name,
				@brand_name       brand_name
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