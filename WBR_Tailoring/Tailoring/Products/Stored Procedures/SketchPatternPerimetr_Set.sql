CREATE PROCEDURE [Products].[SketchPatternPerimetr_Set]
	@sketch_id INT,
	@employee_id INT,
	@xml_data XML
AS
	SET NOCOUNT ON
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @data_tab TABLE(psn_name VARCHAR(25), psn_id INT, ts_name VARCHAR(15), ts_id INT, perimetr INT)
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @state_constructor_take_job_add TINYINT = 9 --Взят в работу конструктором
	DECLARE @state_constructor_take_job_add_rework TINYINT = 15 --Взят на доработку конструктором
	
	SELECT	@error_text = CASE 
	      	                   WHEN s.sketch_id IS NULL THEN 'Эскиза с номером ' + CAST(v.sketch_id AS VARCHAR(10)) + ' не существует'
	      	                   --WHEN s.ss_id NOT IN (@state_constructor_take_job_add, @state_constructor_take_job_add_rework) THEN 
	      	                   --     'Обновлять перемитры можно только в статусе "Взят в работу конструктором".'
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
	
	INSERT INTO @data_tab
	  (
	    psn_name,
	    ts_name,
	    ts_id,
	    perimetr
	  )
	SELECT	ml.value('@psn', 'varchar(25)'),
			ml.value('@ts', 'varchar(15)'),
			ts.ts_id,
			ml.value('@per', 'int')
	FROM	@xml_data.nodes('root/det')x(ml)   
			LEFT JOIN	Products.TechSize ts
				ON	ts.ts_name = ml.value('@ts',
			'varchar(15)')
	
	INSERT INTO Products.PatternSizeName
	  (
	    psn_name
	  )
	SELECT	DISTINCT dt.psn_name
	FROM	@data_tab dt
	WHERE	NOT EXISTS (
	     		SELECT	1
	     		FROM	Products.PatternSizeName psn
	     		WHERE	psn.psn_name = dt.psn_name
	     	)
	
	UPDATE	dt
	SET 	psn_id = psn.psn_id
	FROM	@data_tab dt
			INNER JOIN	Products.PatternSizeName psn
				ON	psn.psn_name = dt.psn_name
	
	SELECT	@error_text = CASE 
	      	                   WHEN dt.ts_id IS NULL THEN 'Размер ' + dt.ts_name + ' не заведен в учетной системе.'
	      	                   WHEN dt.psn_id IS NULL THEN 'Размер периметра ' + dt.psn_name + ' не удалось записать в учетную систему.'
	      	                   WHEN oa_psn.cnt > 1 THEN 'Размер периметра ' + dt.psn_name + ' указан более одного раза'
	      	                   WHEN oa_ts.cnt > 1 THEN 'Размер ' + dt.ts_name + ' указан более одного раза'
	      	                   WHEN dt.perimetr <= 0 THEN 'Периметр для ' + dt.psn_name + ' должен быть больше нуля.'
	      	                   ELSE NULL
	      	              END
	FROM	@data_tab dt   
			OUTER APPLY (
			      	SELECT	COUNT(*)      cnt
			      	FROM	@data_tab     dt2
			      	WHERE	dt2.psn_name = dt.psn_name
			      ) oa_psn
	OUTER APPLY (
	      	SELECT	COUNT(*)      cnt
	      	FROM	@data_tab     dt3
	      	WHERE	dt3.ts_name = dt.ts_name
	      ) oa_ts
	WHERE	dt.ts_id IS NULL
			OR	dt.psn_id IS NULL
			OR	oa_psn.cnt > 1
			OR	oa_ts.cnt > 1
			OR	dt.perimetr <= 0
	
	BEGIN TRY
		;
		MERGE Products.SketchPatternPerimetr t
		USING (
		      	SELECT	@sketch_id       sketch_id,
		      			dt.psn_id,
		      			dt.ts_id,
		      			dt.perimetr,
		      			@dt              dt,
		      			@employee_id     employee_id
		      	FROM	@data_tab        dt
		      ) s
				ON t.sketch_id = s.sketch_id
				AND t.psn_id = s.psn_id
		WHEN MATCHED AND t.perimetr != s.perimetr OR t.ts_id != s.ts_id THEN 
		     UPDATE	
		     SET 	ts_id           = s.ts_id,
		     		perimetr        = s.perimetr,
		     		dt              = s.dt,
		     		employee_id     = s.employee_id
		WHEN NOT MATCHED BY TARGET THEN 
		     INSERT
		     	(
		     		sketch_id,
		     		ts_id,
		     		psn_id,
		     		perimetr,
		     		dt,
		     		employee_id
		     	)
		     VALUES
		     	(
		     		s.sketch_id,
		     		s.ts_id,
		     		s.psn_id,
		     		s.perimetr,
		     		s.dt,
		     		s.employee_id
		     	)
		WHEN NOT MATCHED BY SOURCE AND t.sketch_id = @sketch_id THEN 
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
	END CATCH 