CREATE PROCEDURE [Logistics].[TTNSample_Add]
	@sample_id INT,
	@employee_id INT,
	@ttn_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @ttn_detail_output TABLE (ttns_id INT)
	DECLARE @subject_name          VARCHAR(50),
	        @art_name              VARCHAR(100),
	        @sa                    VARCHAR(76),
	        @ts_name               VARCHAR(15),
	        @place_name            VARCHAR(50),
	        @place_office_name     VARCHAR(50),
	        @place_office_id       INT,
	        @sketch_id             INT,
	        @task_sample_id        INT
	
	SELECT	@error_text = CASE 
	      	                   WHEN t.ttn_id IS NULL THEN 'ТТН с номером ' + CAST(v.ttn_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN t.complite_dt IS NOT NULL THEN 'ТТН с номером ' + CAST(v.ttn_id AS VARCHAR(10)) + ' уже закрытка.'
	      	                   WHEN s.close_dt IS NOT NULL THEN 'Отгрузка № ' + CAST(s.shipping_id AS VARCHAR(10)) + ' уже отправлена'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@ttn_id))v(ttn_id)   
			LEFT JOIN	Logistics.TTN t
				ON	t.ttn_id = v.ttn_id   
			LEFT JOIN	Logistics.Shipping s
				ON	s.shipping_id = t.shipping_id	
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN sam.sample_id IS NULL THEN 'Образца с номером ' + CAST(v.sample_id AS VARCHAR(10)) + ' не существует.'
	      	                   --WHEN sam.sample_id IS NOT NULL AND sam.st_id != 2 THEN 'Не верный тип сэмпла.'
	      	                   ELSE NULL
	      	              END,
			@subject_name = sj.subject_name,
			@art_name = an.art_name,
			@sa = s.sa,
			@ts_name = ts.ts_name,
			@place_name = sp.place_name,
			@place_office_name = ossp.office_name,
			@place_office_id = ossp.office_id,
			@sketch_id = s.sketch_id,
			@task_sample_id = sam.task_sample_id
	FROM	(VALUES(@sample_id))v(sample_id)   
			LEFT JOIN	Manufactory.[Sample] sam   
			INNER JOIN	Products.TechSize ts
				ON	ts.ts_id = sam.ts_id   
			INNER JOIN	Products.Sketch s
				ON	sam.sketch_id = s.sketch_id   
			INNER JOIN	Products.Brand b
				ON	b.brand_id = s.brand_id   
			INNER JOIN	Products.[Subject] sj
				ON	sj.subject_id = s.subject_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id   
			LEFT JOIN	Warehouse.SampleOnPlace sop   
			INNER JOIN	Warehouse.StoragePlace sp   
			INNER JOIN	Warehouse.ZoneOfResponse zor   
			INNER JOIN	Settings.OfficeSetting ossp
				ON	ossp.office_id = zor.office_id
				ON	zor.zor_id = sp.zor_id
				ON	sp.place_id = sop.place_id
				ON	sop.sample_id = sam.sample_id
				ON	sam.sample_id = v.sample_id
	
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	IF EXISTS (
	   	SELECT	1
	   	FROM	Logistics.TTNSample t
	   	WHERE	t.ttn_id = @ttn_id
	   			AND	t.sample_id = @sample_id
	   )
	BEGIN
	    RAISERROR('Этот образец уже в документе', 16, 1)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION	
		
		INSERT INTO Logistics.TTNSample
			(
				ttn_id,
				sample_id,
				employee_id,
				dt
			)OUTPUT	INSERTED.ttns_id
			 INTO	@ttn_detail_output (
			 		ttns_id
			 	)
		VALUES
			(
				@ttn_id,
				@sample_id,
				@employee_id,
				@dt
			)
		
		COMMIT TRANSACTION
		
		SELECT	tdo.ttns_id,
				@subject_name          subject_name,
				@art_name              art_name,
				@sa                    sa,
				@ts_name               ts_name,
				@place_name            place_name,
				@place_office_name     place_office_name,
				@place_office_id       place_office_id,
				@sketch_id             sketch_id,
				@task_sample_id        task_sample_id
		FROM	@ttn_detail_output     tdo
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
		
		
		RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess) WITH LOG;
	END CATCH 