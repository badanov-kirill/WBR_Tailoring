CREATE PROCEDURE [Products].[SketchCompletingRawMaterial_Set]
	@sketch_id INT,
	@employee_id INT,
	@xml_data XML
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @completing_tab TABLE(
	        	rn INT IDENTITY(1, 1),
	        	completing_id INT,
	        	completing_number TINYINT,
	        	frame_width SMALLINT,
	        	okei_id INT,
	        	consumption DECIMAL(9, 3),
	        	comment VARCHAR(200),
	        	rmts XML,
	        	base_rmt_id INT
	        )
	
	DECLARE @sketch_completing_output TABLE(
	        	sc_id INT NOT NULL,
	        	sketch_id INT NOT NULL,
	        	completing_id INT NOT NULL,
	        	completing_number TINYINT NOT NULL,
	        	frame_width SMALLINT NULL,
	        	okei_id INT NOT NULL,
	        	consumption DECIMAL(9, 3) NULL,
	        	comment VARCHAR(200) NULL,
	        	is_deleted BIT NOT NULL,
	        	dt dbo.SECONDSTIME NOT NULL,
	        	employee_id INT NOT NULL,
	        	base_rmt_id INT NOT NULL,
	        	rn INT
	        )
	
	DECLARE @completing_raw_material_tab TABLE(rn INT, rmt_id INT, is_main BIT)
	DECLARE @error_text VARCHAR(MAX)
	
	SELECT	@error_text = CASE 
	      	                   WHEN s.sketch_id IS NULL THEN 'Эскиза с номером ' + CAST(v.sketch_id AS VARCHAR(10)) + ' не существует'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@sketch_id))v(sketch_id)   
			LEFT JOIN	Products.Sketch s
				ON	s.sketch_id = v.sketch_id   
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	INSERT INTO @completing_tab
	  (
	    completing_id,
	    completing_number,
	    frame_width,
	    okei_id,
	    consumption,
	    comment,
	    rmts
	  )
	SELECT	ml.value('@id', 'int'),
			ml.value('@num', 'tinyint'),
			ml.value('@fw', 'smallint'),
			ml.value('@okei', 'int'),
			ml.value('@cn', 'decimal(9,3)'),
			ml.value('@com', 'varchar(200)'),
			ml.query('rmts')
	FROM	@xml_data.nodes('comgs/comg')x(ml)
	
	INSERT INTO @completing_raw_material_tab
	  (
	    rn,
	    rmt_id,
	    is_main
	  )
	SELECT	t.rn,
			ml.value('@id', 'int'),
			ml.value('@m', 'bit')
	FROM	@completing_tab t   
			CROSS APPLY t.rmts.nodes('rmts/rmt')x(ml)
	
	SELECT	@error_text = CASE 
	      	                   WHEN c.completing_id IS NULL THEN 'Комплектации с кодом ' + CAST(dt.completing_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN o2.okei_id IS NULL THEN 'Кода ОКЕИ с ' + CAST(dt.okei_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN dt.completing_number IS NULL THEN 'В строчке номер ' + CAST(dt.rn AS VARCHAR(10)) + ' для ' + c.completing_name +
	      	                        ' не указан порядковый номер.'
	      	                   WHEN crmt.rn IS NULL THEN 'Для строчки комплектации ' + c.completing_name + CAST(dt.completing_number AS VARCHAR(10)) +
	      	                        ' не указан ни один вариант материала.'
	      	                   WHEN rmt.rmt_id IS NULL THEN 'Типа материала с кодом ' + CAST(crmt.rmt_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN rmt.stor_unit_residues_okei_id != c.okei_id THEN 'У материала ' + rmt.rmt_name + ' еденица хранения остатков(' + o.symbol +
	      	                        ') не совпадает еденицей измерения комплектующей ' + c.completing_name + ' (' + o2.symbol + ')'
	      	                   WHEN oa_ct.cnt > 1 THEN 'Cтрочка комплектации ' + c.completing_name + CAST(dt.completing_number AS VARCHAR(10)) +
	      	                        ' указана более одного раза.'
	      	                   WHEN oa_rm.cnt_main = 0 THEN 'Cтрочка комплектации ' + c.completing_name + CAST(dt.completing_number AS VARCHAR(10)) +
	      	                        ' не имеет ни одного основного материала'
	      	                   WHEN oa_rm.cnt_main > 1 THEN 'Cтрочка комплектации ' + c.completing_name + CAST(dt.completing_number AS VARCHAR(10)) +
	      	                        ' имеет более одного основного материала'
	      	                   WHEN oa_rm.cnt != oa_rm.cnt_dst THEN 'Cтрочка комплектации ' + c.completing_name + CAST(dt.completing_number AS VARCHAR(10)) +
	      	                        ' имеет повторяющиеся материалы'
	      	                   ELSE NULL
	      	              END
	FROM	@completing_tab dt   
			LEFT JOIN	@completing_raw_material_tab crmt
				ON	crmt.rn = dt.rn   
			LEFT JOIN	Material.RawMaterialType rmt   
			INNER JOIN	Qualifiers.OKEI o
				ON	o.okei_id = rmt.stor_unit_residues_okei_id
				ON	crmt.rmt_id = rmt.rmt_id   
			LEFT JOIN	Material.Completing c
				ON	c.completing_id = dt.completing_id   
			LEFT JOIN	Qualifiers.OKEI o2
				ON	o2.okei_id = dt.okei_id   
			OUTER APPLY (
			      	SELECT	COUNT(*) cnt
			      	FROM	@completing_tab ct
			      	WHERE	ct.completing_id = dt.completing_id
			      			AND	ct.completing_number = dt.completing_number
			      ) oa_ct
	OUTER APPLY (
	      	SELECT	SUM(CASE WHEN crmt2.is_main = 1 THEN 1 ELSE 0 END) cnt_main,
	      			COUNT(crmt2.rmt_id) cnt,
	      			COUNT(DISTINCT crmt2.rmt_id) cnt_dst
	      	FROM	@completing_raw_material_tab crmt2
	      	WHERE	crmt2.rn = dt.rn
	      ) oa_rm
	WHERE	c.completing_id IS NULL
			OR	o2.okei_id IS NULL
			OR	dt.completing_number IS NULL
			OR	crmt.rn IS NULL
			OR	rmt.rmt_id IS NULL
			OR	rmt.stor_unit_residues_okei_id != c.okei_id
			OR	oa_ct.cnt > 1
			OR	oa_rm.cnt_main != 1
			OR	oa_rm.cnt != oa_rm.cnt_dst
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END	
	
	UPDATE	ct
	SET 	base_rmt_id = crmt.rmt_id
	FROM	@completing_tab ct
			INNER JOIN	@completing_raw_material_tab crmt
				ON	crmt.rn = ct.rn
				AND	crmt.is_main = 1
	
	SELECT	@error_text = CASE 
	      	                   WHEN dt.base_rmt_id IS NULL THEN 'В строчке номер ' + CAST(dt.rn AS VARCHAR(10)) + ' не указан базовый материал'
	      	                   ELSE NULL
	      	              END
	FROM	@completing_tab dt
	WHERE	dt.base_rmt_id IS NULL 
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END	
	
	BEGIN TRY
		BEGIN TRANSACTION 
		;
		WITH cte_Target AS(
			SELECT	sc.sc_id,
					sc.sketch_id,
					sc.completing_id,
					sc.completing_number,
					sc.frame_width,
					sc.okei_id,
					sc.consumption,
					sc.comment,
					sc.is_deleted,
					sc.dt,
					sc.employee_id,
					sc.base_rmt_id
			FROM	Products.SketchCompleting sc
			WHERE	sc.sketch_id = @sketch_id
		)
		MERGE cte_Target t
		USING @completing_tab s
				ON s.completing_id = t.completing_id
				AND s.completing_number = t.completing_number
		WHEN MATCHED THEN 
		     UPDATE	
		     SET 	frame_width     = s.frame_width,
		     		okei_id         = s.okei_id,
		     		consumption     = ISNULL(s.consumption, t.consumption),
		     		comment         = s.comment,
		     		dt              = @dt,
		     		employee_id     = @employee_id,
		     		is_deleted      = 0,
		     		base_rmt_id     = s.base_rmt_id
		WHEN NOT MATCHED BY TARGET THEN 
		     INSERT
		     	(
		     		sketch_id,
		     		completing_id,
		     		completing_number,
		     		frame_width,
		     		okei_id,
		     		consumption,
		     		comment,
		     		is_deleted,
		     		dt,
		     		employee_id,
		     		base_rmt_id
		     	)
		     VALUES
		     	(
		     		@sketch_id,
		     		s.completing_id,
		     		s.completing_number,
		     		s.frame_width,
		     		s.okei_id,
		     		s.consumption,
		     		s.comment,
		     		0,
		     		@dt,
		     		@employee_id,
		     		s.base_rmt_id
		     	)
		WHEN NOT MATCHED BY SOURCE THEN 
		     UPDATE	
		     SET 	is_deleted      = 1,
		     		dt              = @dt,
		     		employee_id     = @employee_id
		     		OUTPUT	INSERTED.sc_id,
		     				INSERTED.sketch_id,
		     				INSERTED.completing_id,
		     				INSERTED.completing_number,
		     				INSERTED.frame_width,
		     				INSERTED.okei_id,
		     				INSERTED.consumption,
		     				INSERTED.comment,
		     				INSERTED.is_deleted,
		     				INSERTED.dt,
		     				INSERTED.employee_id,
		     				INSERTED.base_rmt_id,
		     				s.rn
		     		INTO	@sketch_completing_output (
		     				sc_id,
		     				sketch_id,
		     				completing_id,
		     				completing_number,
		     				frame_width,
		     				okei_id,
		     				consumption,
		     				comment,
		     				is_deleted,
		     				dt,
		     				employee_id,
		     				base_rmt_id,
		     				rn
		     			);
		
		;
		WITH cte_Target AS(
			SELECT	scrm.scrm_id,
					scrm.sc_id,
					scrm.rmt_id,
					scrm.dt,
					scrm.employee_id
			FROM	Products.SketchCompletingRawMaterial scrm
			WHERE	EXISTS (
			     		SELECT	1
			     		FROM	@sketch_completing_output so
			     		WHERE	so.sc_id = scrm.sc_id
			     	)
		)
		MERGE cte_Target t
		USING (
		      	SELECT	sco.sc_id,
		      			crmt.rmt_id
		      	FROM	@completing_raw_material_tab crmt   
		      			INNER JOIN	@sketch_completing_output sco
		      				ON	sco.rn = crmt.rn
		      ) s
				ON t.rmt_id = s.rmt_id
				AND t.sc_id = s.sc_id
		WHEN MATCHED THEN 
		     UPDATE	
		     SET 	dt              = @dt,
		     		employee_id     = @employee_id
		WHEN NOT MATCHED BY TARGET THEN 
		     INSERT
		     	(
		     		sc_id,
		     		rmt_id,
		     		dt,
		     		employee_id
		     	)
		     VALUES
		     	(
		     		s.sc_id,
		     		s.rmt_id,
		     		@dt,
		     		@employee_id
		     	)
		WHEN NOT MATCHED BY SOURCE THEN 
		     DELETE	; 
		
		INSERT INTO History.SketchCompleting
		  (
		    sc_id,
		    sketch_id,
		    completing_id,
		    completing_number,
		    frame_width,
		    okei_id,
		    consumption,
		    comment,
		    is_deleted,
		    dt,
		    employee_id,
		    base_rmt_id
		  )
		SELECT	sco.sc_id,
				sco.sketch_id,
				sco.completing_id,
				sco.completing_number,
				sco.frame_width,
				sco.okei_id,
				sco.consumption,
				sco.comment,
				sco.is_deleted,
				sco.dt,
				sco.employee_id,
				sco.base_rmt_id
		FROM	@sketch_completing_output sco
		
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
		
		RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess) WITH LOG;
	END CATCH 