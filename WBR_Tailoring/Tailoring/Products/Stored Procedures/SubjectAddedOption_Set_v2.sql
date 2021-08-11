CREATE PROCEDURE [Products].[SubjectAddedOption_Set_v2]
	@subject_name VARCHAR(50),
	@subject_name_sf VARCHAR(50) = NULL,
	@data_xml XML,
	@employee_id INT,
	@subject_erp_id INT,
	@subject_gs1_id INT = NULL
AS
	SET NOCOUNT ON 
	SET XACT_ABORT ON

	DECLARE @dt dbo.SECONDSTIME = GETDATE() 
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @subject_id INT	
	
	DECLARE @tab_ao TABLE(
	        	rn INT IDENTITY(1, 1) PRIMARY KEY CLUSTERED NOT NULL,
	        	content INT,
	        	ao_name VARCHAR(50),
	        	parent_name VARCHAR(50),
	        	is_bool BIT,
	        	si_name VARCHAR(50),
	        	si_id INT,
	        	ao_type_id INT,
	        	required_mode TINYINT,
	        	is_sketch BIT,
	        	content_id         INT ,
				content_ext_id     INT 
	        )
	
	DECLARE @subjects_output TABLE (subject_id INT)
	
	INSERT INTO @tab_ao
	  (
	    ao_name,
	    parent_name,
	    is_bool,
	    si_name,
	    si_id,
	    ao_type_id,
	    required_mode,
	    is_sketch, 
	    content_id, 
	    content_ext_id
	  )
	SELECT	
			ml.value('@name', 'varchar(50)'),
			ml.value('@pname', 'varchar(50)'),
			ml.value('@bol', 'bit'),
			ml.value('@si', 'varchar(50)'),
			s.si_id,
			ml.value('@type', 'int'),
			ml.value('@rm', 'tinyint'),
			ml.value('@sk', 'bit'),
			ml.value('@id', 'int'),
			ml.value('@pid', 'int')
	FROM	@data_xml.nodes('root/ao')x(ml)   
			LEFT JOIN	Products.SI s
				ON	s.si_name = ml.value('@si',
			'varchar(50)')   
	
	SELECT	@error_text = CASE 
	      	                   WHEN ta.ao_name IS NULL THEN 'Не указано имя в строке № ' + CAST(ta.rn AS VARCHAR(10))
	      	                   WHEN ta.si_name IS NOT NULL AND ta.si_id IS NULL THEN 'Для еденицы измерения ' + ta.si_name + ' не найдено соответствие'
	      	                   WHEN ta.ao_type_id IS NULL THEN 'Не указан тип для ' + ta.ao_name + ' в строке № ' + CAST(ta.rn AS VARCHAR(10))
	      	                   WHEN ta.is_bool IS NULL AND ta.content_ext_id IS NULL THEN 'Не указан признак булево в строке № ' + CAST(ta.rn AS VARCHAR(10))
	      	                   WHEN ta.parent_name IS NOT NULL AND tap.ao_name IS NULL THEN 'Не передан родитель для допсвойства ' + ta.ao_name +
	      	                        ' , имя родетеля ' + ta.parent_name
	      	                   ELSE NULL
	      	              END
	FROM	@tab_ao ta   
			LEFT JOIN	@tab_ao tap
				ON	ta.content_id = tap.content_id
				AND	tap.content_ext_id IS NULL
	WHERE	ta.ao_name IS NULL
			OR	(ta.si_name IS NOT NULL AND ta.si_id IS NULL)
			OR	ta.ao_type_id IS NULL
			OR	(ta.is_bool IS NULL AND ta.content_ext_id IS NULL)
			OR	(ta.parent_name IS NOT NULL AND tap.ao_name IS NULL) 
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	IF NOT EXISTS (SELECT 1 FROM Products.[Subject] s WHERE s.erp_id = @subject_erp_id) AND @subject_name_sf IS NULL
	BEGIN
		RAISERROR('Для нового предмета обязательно указывать имя собственное', 16, 1)
	    RETURN
	END
	
	BEGIN TRY
	BEGIN TRANSACTION 
		;
		MERGE Products.[Subject] t
		USING (
		      	SELECT	@subject_name        subject_name,
		      			@subject_name_sf     subject_name_sf,
		      			@subject_erp_id      subject_erp_id
		      ) s
				ON s.subject_erp_id = t.erp_id
		WHEN MATCHED AND (t.subject_name_sf != ISNULL(s.subject_name_sf, t.subject_name_sf) OR t.isdeleted = 1 OR t.subject_name != s.subject_name) THEN 
		     UPDATE	
		     SET 	t.subject_name = s.subject_name,
		     		employee_id = @employee_id,
		     		dt = @dt,
		     		isdeleted = 0,
		     		subject_name_sf = ISNULL(s.subject_name_sf, t.subject_name_sf), subject_gs1_id = /*{ subject_gs1_id }*/,
		     		block_gs1 = /*{ block_gs1 }*/
		     	
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
		     		ISNULL(s.subject_name_sf, s.subject_name),
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
						ao.erp_id,
						ao.is_constructor,
						ao.content_id,
						ao.content_ext_id
				FROM	Products.AddedOption ao
				WHERE	ao.ao_id_parent IS NULL
			)
		MERGE cte_target t
		USING (
		      	SELECT	ta.ao_name,
		      			ta.is_bool,
		      			ta.si_id,
		      			ta.ao_type_id,
		      			ta.content_id,
		      			ta.content_ext_id
		      	FROM	@tab_ao ta
		      	WHERE	ta.content_ext_id IS NULL
		      ) s
				ON t.content_id = s.content_id
		WHEN MATCHED AND (t.ao_name Collate Cyrillic_General_CS_AS != s.ao_name OR t.isdeleted = 1 OR t.si_id != s.si_id OR t.ao_type_id != s.ao_type_id OR t.is_bool != s.is_bool) THEN 
		     UPDATE	
		     SET 	employee_id     = @employee_id,
		     		dt              = @dt,
		     		isdeleted       = 0,
		     		si_id           = s.si_id,
		     		ao_type_id      = s.ao_type_id,
		     		is_bool         = s.is_bool,
		     		content_id		= s.content_id,
		     		content_ext_id	= NULL,
		     		ao_name			= s.ao_name
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
		     		content_id,
		     		erp_id
		     	)
		     VALUES
		     	(
		     		s.ao_name,
		     		@employee_id,
		     		@dt,
		     		0,
		     		'',
		     		s.si_id,
		     		s.ao_type_id,
		     		s.is_bool,
		     		s.content_id,
		     		s.content_id
		     	);
		
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
					ao.erp_id, 
					ao.is_constructor,
					ao.content_id, 
					ao.content_ext_id
			FROM	Products.AddedOption ao
			WHERE	EXISTS (SELECT 1
			     	                    FROM	@tab_ao tao
										INNER JOIN Products.AddedOption ao2
											ON ao2.content_id = tao.content_id
											AND ao2.ao_id_parent IS NULL
			     	                    WHERE ao2.ao_id = ao.ao_id_parent
										)
			     	AND ao.ao_id_parent IS NOT NULL 
		)
		MERGE cte_target t
		USING (
		      	SELECT	ta.ao_name,
		      			ta.content_id,
		      			ta.content_ext_id,
		      			ao2.ao_id ao_id_parent,
		      			ta.si_id, 
		      			ta.ao_type_id,
		      			ta.is_bool
		      	FROM	@tab_ao ta   
		      			INNER JOIN	Products.AddedOption ao2
		      				ON	ao2.content_id = ta.content_id
		      				AND	ao2.ao_id_parent IS NULL
		      	WHERE	ta.content_ext_id IS NOT NULL
		      ) s
				ON t.content_ext_id = s.content_ext_id AND t.ao_id_parent = s.ao_id_parent
		WHEN MATCHED AND (		     	
		     	 t.isdeleted = 1
		     	OR t.content_ext_id IS NULL
		     	OR t.ao_name Collate Cyrillic_General_CS_AS != s.ao_name
		     	OR t.si_id != s.si_id OR t.ao_type_id != s.ao_type_id OR t.is_bool != s.is_bool
		     ) THEN 
		     UPDATE	
		     SET 	employee_id     = @employee_id,
		     		dt              = @dt,
		     		isdeleted       = 0,		     		
		     		content_id		= s.content_id,
		     		content_ext_id	= s.content_ext_id,
		     		ao_name			=	s.ao_name,
		     		si_id           = s.si_id,
		     		ao_type_id      = s.ao_type_id,
		     		is_bool         = s.is_bool
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
		     		content_id,
		     		content_ext_id
		     	)
		     VALUES
		     	(
		     		s.ao_id_parent,
		     		s.ao_name,
		     		@employee_id,
		     		@dt,
		     		0,
		     		'',
		     		null,
		     		NULL,
		     		NULL,
		     		s.content_id,
		     		s.content_ext_id
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
		      				ON	ao.content_id = ta.content_id
		      				AND isnull(ao.content_ext_id, 0) = isnull(ta.content_ext_id, 0)		      			
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