CREATE PROCEDURE [Products].[SubjectAddedOption_Set]
	@subject_name VARCHAR(50),
	@subject_name_sf VARCHAR(50),
	@data_xml XML,
	@employee_id INT,
	@subject_erp_id INT
AS
	SET NOCOUNT ON 
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	DECLARE @dt dbo.SECONDSTIME = GETDATE() 
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @subject_id INT	
	
	DECLARE @tab_ao TABLE(
	        	rn INT IDENTITY(1, 1) PRIMARY KEY CLUSTERED NOT NULL,
	        	erp_ao_id INT,
	        	erp_ao_id_parent INT,
	        	ao_id_parent INT,
	        	ao_name VARCHAR(50),
	        	parent_name VARCHAR(50),
	        	ao_name_eng VARCHAR(50),
	        	is_bool BIT,
	        	si_name VARCHAR(50),
	        	si_id INT,
	        	ao_type_name VARCHAR(100),
	        	ao_type_id INT,
	        	required_mode TINYINT,
	        	is_sketch BIT
	        )
	
	DECLARE @subjects_output TABLE (subject_id INT)
	
	INSERT INTO @tab_ao
	  (
	    erp_ao_id,
	    erp_ao_id_parent,
	    ao_name,
	    parent_name,
	    ao_name_eng,
	    is_bool,
	    si_name,
	    ao_type_name,
	    si_id,
	    ao_type_id,
	    required_mode,
	    is_sketch
	  )
	SELECT	ml.value('@id', 'int'),
			ml.value('@pid', 'int'),
			ml.value('@name', 'varchar(50)'),
			ml.value('@pname', 'varchar(50)'),
			ml.value('@name_eng', 'varchar(50)'),
			ml.value('@bol', 'bit'),
			ml.value('@si', 'varchar(50)'),
			ml.value('@type', 'varchar(100)'),
			s.si_id,
			aot.ao_type_id,
			ml.value('@rm', 'tinyint'),
			ml.value('@sk', 'bit')
	FROM	@data_xml.nodes('root/ao')x(ml)   
			LEFT JOIN	Products.SI s
				ON	s.si_name = ml.value('@si',
			'varchar(50)')   
			LEFT JOIN	Products.AddedOptionType aot
				ON	aot.ao_type_name = ml.value('@type',
			'varchar(100)')
	
	
	SELECT	@error_text = CASE 
	      	                   WHEN ta.ao_name IS NULL THEN 'Не указано имя в строке № ' + CAST(ta.rn AS VARCHAR(10))
	      	                   WHEN ta.si_name IS NOT NULL AND ta.si_id IS NULL THEN 'Для еденицы измерения ' + ta.si_name + ' не найдено соответствие'
	      	                   WHEN ta.ao_type_id IS NULL THEN 'Не указан тип для ' + ta.ao_name + ' в строке № ' + CAST(ta.rn AS VARCHAR(10))
	      	                   WHEN ta.is_bool IS NULL THEN 'Не указан признак булево в строке № ' + CAST(ta.rn AS VARCHAR(10))
	      	                   WHEN ta.parent_name IS NOT NULL AND tap.ao_name IS NULL THEN 'Не передан родитель для допсвойства ' + ta.ao_name +
	      	                        ' , имя родетеля ' + ta.parent_name
	      	                   ELSE NULL
	      	              END
	FROM	@tab_ao ta   
			LEFT JOIN	@tab_ao tap
				ON	ta.erp_ao_id_parent = tap.erp_ao_id
				AND	tap.parent_name IS NULL
	WHERE	ta.ao_name IS NULL
			OR	(ta.si_name IS NOT NULL AND ta.si_id IS NULL)
			OR	ta.ao_type_id IS NULL
			OR	ta.is_bool IS NULL
			OR	(ta.parent_name IS NOT NULL AND tap.ao_name IS NULL) 
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		;
		MERGE Products.[Subject] t
		USING (
		      	SELECT	@subject_name        subject_name,
		      			@subject_name_sf     subject_name_sf,
		      			@subject_erp_id      subject_erp_id
		      ) s
				ON s.subject_erp_id = t.erp_id
		WHEN MATCHED AND (t.subject_name_sf != s.subject_name_sf OR t.isdeleted = 1 OR t.subject_name != s.subject_name) THEN 
		     UPDATE	
		     SET 	t.subject_name = s.subject_name,
		     		employee_id = @employee_id,
		     		dt = @dt,
		     		isdeleted = 0,
		     		subject_name_sf = s.subject_name_sf
		WHEN NOT MATCHED THEN 
		     INSERT
		     	(
		     		subject_name,
		     		employee_id,
		     		dt,
		     		isdeleted,
		     		subject_name_sf,
		     		erp_id
		     	)
		     VALUES
		     	(
		     		s.subject_name,
		     		@employee_id,
		     		@dt,
		     		0,
		     		s.subject_name_sf,
		     		s.subject_erp_id
		     	) 
		     OUTPUT	INSERTED.subject_id
		     INTO	@subjects_output (
		     		subject_id
		     	);
		
		SELECT	@subject_id = so.subject_id
		FROM	@subjects_output so
		
		IF @subject_id IS NULL
		BEGIN
		    SELECT	@subject_id = s.subject_id
		    FROM	Products.[Subject] s
		    WHERE	s.erp_id = @subject_erp_id
		END;
		
		MERGE Products.AddedOption t
		USING (
		      	SELECT	ta.erp_ao_id,
		      			ta.erp_ao_id_parent,
		      			ta.ao_name,
		      			ta.ao_name_eng,
		      			ta.is_bool,
		      			ta.si_id,
		      			ta.ao_type_id
		      	FROM	@tab_ao ta
		      	WHERE	ta.erp_ao_id_parent IS NULL
		      ) s
				ON t.erp_id = s.erp_ao_id
		WHEN MATCHED AND (t.ao_name != s.ao_name OR t.isdeleted = 1 OR t.ao_name_eng != s.ao_name_eng OR t.si_id != s.si_id OR t.ao_type_id != s.ao_type_id OR t.is_bool != s.is_bool) THEN 
		     UPDATE	
		     SET 	ao_name         = s.ao_name,
		     		employee_id     = @employee_id,
		     		dt              = @dt,
		     		isdeleted       = 0,
		     		ao_name_eng     = ISNULL(s.ao_name_eng, t.ao_name_eng),
		     		si_id           = s.si_id,
		     		ao_type_id      = s.ao_type_id,
		     		is_bool         = s.is_bool,
		     		t.ao_id_parent = NULL
		WHEN NOT MATCHED THEN 
		     INSERT
		     	(
		     		ao_name,
		     		employee_id,
		     		dt,
		     		isdeleted,
		     		ao_name_eng,
		     		si_id,
		     		ao_type_id,
		     		is_bool,
		     		erp_id
		     	)
		     VALUES
		     	(
		     		s.ao_name,
		     		@employee_id,
		     		@dt,
		     		0,
		     		s.ao_name_eng,
		     		s.si_id,
		     		s.ao_type_id,
		     		s.is_bool,
		     		s.erp_ao_id
		     	);
		
		UPDATE	tao
		SET 	ao_id_parent = ao.ao_id
		FROM	@tab_ao tao
				INNER JOIN	Products.AddedOption ao
					ON	tao.erp_ao_id_parent = ao.erp_id
		
		;
		WITH cte_target AS
		(
			SELECT	ao.ao_id,
					ao.ao_id_parent,
					ao.ao_name,
					ao.employee_id,
					ao.dt,
					ao.isdeleted,
					ao.ao_name_eng,
					ao.si_id,
					ao.ao_type_id,
					ao.is_bool,
					ao.erp_id
			FROM	Products.AddedOption ao
			WHERE	ao.ao_id_parent IN (SELECT	tao.ao_id_parent
			     	                    FROM	@tab_ao tao)
		)
		MERGE cte_target t
		USING (
		      	SELECT	ta.erp_ao_id,
		      			ta.ao_name,
		      			ta.ao_name_eng,
		      			ta.ao_id_parent,
		      			ta.is_bool,
		      			ta.si_id,
		      			ta.ao_type_id
		      	FROM	@tab_ao ta
		      	WHERE	ta.ao_id_parent IS NOT NULL
		      ) s
				ON t.erp_id = s.erp_ao_id
		WHEN MATCHED AND (
		     	t.ao_name != s.ao_name
		     	OR t.ao_id_parent != s.ao_id_parent
		     	--OR t.isdeleted != 0
		     	OR t.ao_name_eng != s.ao_name_eng
		     	OR t.si_id != s.si_id
		     	OR t.ao_type_id != s.ao_type_id
		     	OR t.is_bool != s.is_bool
		     ) THEN 
		     UPDATE	
		     SET 	ao_name         = s.ao_name,
		     		employee_id     = @employee_id,
		     		dt              = @dt,
		     		isdeleted       = 0,
		     		ao_name_eng     = s.ao_name_eng,
		     		si_id           = s.si_id,
		     		ao_type_id      = s.ao_type_id,
		     		is_bool         = s.is_bool,
		     		t.ao_id_parent = s.ao_id_parent
		WHEN NOT MATCHED BY TARGET THEN 
		     INSERT
		     	(
		     		ao_id_parent,
		     		ao_name,
		     		employee_id,
		     		dt,
		     		isdeleted,
		     		ao_name_eng,
		     		si_id,
		     		ao_type_id,
		     		is_bool,
		     		erp_id
		     	)
		     VALUES
		     	(
		     		s.ao_id_parent,
		     		s.ao_name,
		     		@employee_id,
		     		@dt,
		     		0,
		     		s.ao_name_eng,
		     		s.si_id,
		     		s.ao_type_id,
		     		s.is_bool,
		     		s.erp_ao_id
		     	)
		WHEN NOT MATCHED BY SOURCE THEN 
		     UPDATE	
		     SET 	employee_id     = @employee_id,
		     		dt              = @dt,
		     		isdeleted       = 1;
		
		WITH cte_target AS
		(
			SELECT	sao.subject_id,
					sao.ao_id,
					sao.dt,
					sao.employee_id,
					sao.required_mode,
					sao.is_sketch
			FROM	Products.SubjectAddedOption sao
			WHERE	sao.subject_id = @subject_id
		)     		
		MERGE cte_target t
		USING (
		      	SELECT	ao.ao_id,
		      			ta.required_mode,
		      			ta.is_sketch
		      	FROM	@tab_ao ta   
		      			INNER JOIN	Products.AddedOption ao
		      				ON	ao.erp_id = ta.erp_ao_id
		      	WHERE	ta.required_mode IS NOT NULL
		      ) s
				ON t.ao_id = s.ao_id
		WHEN MATCHED AND t.required_mode != s.required_mode THEN 
		     UPDATE	
		     SET 	dt                = @dt,
		     		employee_id       = @employee_id,
		     		required_mode     = s.required_mode,
		     		is_sketch         = s.is_sketch
		WHEN NOT MATCHED BY TARGET THEN 
		     INSERT
		     	(
		     		subject_id,
		     		ao_id,
		     		dt,
		     		employee_id,
		     		required_mode,
		     		is_sketch
		     	)
		     VALUES
		     	(
		     		@subject_id,
		     		s.ao_id,
		     		@dt,
		     		@employee_id,
		     		s.required_mode,
		     		s.is_sketch
		     	)
		WHEN NOT MATCHED BY SOURCE THEN 
		     DELETE	;
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