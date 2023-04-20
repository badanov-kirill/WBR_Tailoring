CREATE PROCEDURE [Manufactory].[Layout_Set_v2]
	@layout_id INT = NULL,
	@tl_id INT,
	@completing_id INT,
	@completing_number TINYINT,
	@frame_width SMALLINT,
	@layout_length DECIMAL(9, 3),
	@effective_percent DECIMAL(5, 3),
	@sketch_id INT,
	@consumption DECIMAL(9, 3),
	@ts_xml XML,
	@added_sketch_xml XML,
	@added_spcv_xml XML,
	@employee_id INT,
	@comment VARCHAR(200) = NULL,
	@is_deleted BIT = 0
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @ts_tab TABLE(ts_id INT, completing_qty DECIMAL(9, 3))
	DECLARE @added_sketch_tab TABLE (rn INT IDENTITY(1, 1) PRIMARY KEY CLUSTERED, sketch_id INT, completing_id INT, completing_number TINYINT, consumption DECIMAL(9, 3), ts_xml XML)
	DECLARE @added_sketch_tab_ts TABLE (sketch_id INT, ts_id INT, completing_qty DECIMAL(9, 3), rn INT)
	DECLARE @added_spcv_tab TABLE (spcv_id INT)
	DECLARE @added_spcv_tab_out TABLE (spcv_id INT)
	DECLARE @layout_output TABLE (layout_id INT)
	DECLARE @layout_added_sketch_output TABLE (las_id INT, sketch_id INT, act CHAR(1), completing_id INT, completing_number TINYINT)
	DECLARE @base_spcv_id INT
	DECLARE @status_add_as_compain TINYINT = 10
	DECLARE @cv_status_add_as_compain TINYINT = 11 --Создан как компаньен
	DECLARE @cvc_state_covered_wh TINYINT = 3
	DECLARE @sketch_plan_output TABLE (sp_id INT, sketch_id INT)
	DECLARE @sew_office_id INT
	DECLARE @sew_fabricator_id INT
	DECLARE @spcv_output TABLE(
	        	spcv_id INT NOT NULL,
	        	sp_id INT NOT NULL,
	        	spcv_name VARCHAR(36) NOT NULL,
	        	cvs_id TINYINT NOT NULL,
	        	qty SMALLINT NOT NULL,
	        	employee_id INT NOT NULL,
	        	dt dbo.SECONDSTIME NOT NULL,
	        	is_deleted BIT NOT NULL,
	        	comment VARCHAR(300) NULL,
	        	pan_id INT NULL,
	        	corrected_qty SMALLINT NULL,
	        	begin_plan_delivery_dt DATE NULL,
	        	end_plan_delivery_dt DATE NULL,
	        	sew_office_id INT NULL,
	        	sew_deadline_dt DATE NULL,
	        	cost_plan_year SMALLINT NULL,
	        	cost_plan_month TINYINT NULL,
				fabricator_id INT NULL
	)
	DECLARE @proc_id INT

	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID
	
	SELECT	@error_text = CASE 
	      	                   WHEN tl.tl_id IS NULL THEN 'Задания с номером ' + CAST(v.tl_id AS VARCHAR(10)) + ' не существует.'
	      	                   ELSE NULL
	      	              END,
	      	@sew_office_id = spcv.sew_office_id,
			@base_spcv_id = tl.spcv_id,
			@sew_fabricator_id = sp.sew_fabricator_id
	FROM	(VALUES(@tl_id))v(tl_id)   
			LEFT JOIN	Manufactory.TaskLayout tl
			INNER JOIN Planing.SketchPlanColorVariant spcv
			ON spcv.spcv_id = tl.spcv_id
				ON	tl.tl_id = v.tl_id
			INNER JOIN Planing.SketchPlan sp
				ON sp.sp_id = spcv.sp_id
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END

	IF @sew_fabricator_id  is NULL
	BEGIN
	    RAISERROR('%s', 16, 1, 'Изготовитель не определен')
	    RETURN
	END
	
	IF @layout_id IS NOT NULL
	   AND NOT EXISTS (
	       	SELECT	1
	       	FROM	Manufactory.Layout l
	       	WHERE	l.layout_id = @layout_id
	       )
	BEGIN
	    RAISERROR('Раскладки с кодом %d не существует.', 16, 1, @layout_id)
	    RETURN
	END
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Material.Completing c
	   	WHERE	c.completing_id = @completing_id
	   )
	BEGIN
	    RAISERROR('Комплектации с кодом %d не существует.', 16, 1, @completing_id)
	    RETURN
	END
	
	IF ISNULL(@frame_width, 0) <= 0
	BEGIN
	    RAISERROR('Не корректная ширина рамки', 16, 1)
	    RETURN
	END
	
	IF ISNULL(@layout_length, 0) <= 0
	BEGIN
	    RAISERROR('Не корректная длина раскладки', 16, 1)
	    RETURN
	END
	
	IF ISNULL(@completing_number, 0) <= 0
	BEGIN
	    RAISERROR('Не корректный номер комплектации', 16, 1)
	    RETURN
	END
	
	IF ISNULL(@effective_percent, 0) <= 0
	   OR @effective_percent > 100
	BEGIN
	    RAISERROR('Не корректный процент эффективности', 16, 1)
	    RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN s.sketch_id IS NULL THEN 'Эскиза с кодом ' + CAST(v.sketch_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN s.is_deleted = 1 THEN 'Эскиз с кодом ' + CAST(v.sketch_id AS VARCHAR(10)) + ' удален.'
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
		
	INSERT INTO @ts_tab
	  (
	    ts_id,
	    completing_qty
	  )
	SELECT	ml.value('@id', 'int') ts_id,
			ml.value('@qty', 'decimal(9,3)') completing_qty
	FROM	@ts_xml.nodes('tss/ts')x(ml)
	
	INSERT INTO @added_sketch_tab
	  (
	    sketch_id,
	    completing_id,
	    completing_number,
	    consumption,
	    ts_xml
	  )
	SELECT	ml.value('@sid', 'int')          sketch_id,
			ml.value('@cid', 'int')          completing_id,
			ml.value('@cnum', 'tinyint')     completing_number,
			ml.value('@cons', 'decimal(9,3)') consumption,
			ml.query('tss')                  ts_xml
	FROM	@added_sketch_xml.nodes('root/det')x(ml)
	
	INSERT INTO @added_sketch_tab_ts
	  (
	    sketch_id,
	    ts_id,
	    completing_qty,
	    rn
	  )
	SELECT	ast.sketch_id,
			ml.value('@id', 'int')     ts_id,
			ml.value('@qty', 'decimal(9,3)') completing_qty,
			ast.rn
	FROM	@added_sketch_tab       ast   
			CROSS APPLY ast.ts_xml.nodes('tss/ts')x(ml)
	
	SELECT	@error_text = CASE 
	      	                   WHEN ts.ts_id IS NULL THEN 'Размера с кодом ' + CAST(tst.ts_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN ISNULL(tst.completing_qty, 0) = 0 THEN 'Не корректно указано количество комплектов в настиле, для размера ' + ts.ts_name
	      	                   ELSE NULL
	      	              END
	FROM	@ts_tab tst   
			LEFT JOIN	Products.TechSize ts
				ON	ts.ts_id = tst.ts_id
	WHERE	ts.ts_id IS NULL
			OR	ISNULL(tst.completing_qty, 0) = 0
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN ts.ts_id IS NULL THEN 'Размера с кодом ' + CAST(tst.ts_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN ISNULL(tst.completing_qty, 0) <= 0 THEN 'Не корректно указано количество комплектов в настиле, для размера ' + ts.ts_name
	      	                   ELSE NULL
	      	              END
	FROM	@added_sketch_tab_ts tst   
			LEFT JOIN	Products.TechSize ts
				ON	ts.ts_id = tst.ts_id
	WHERE	ts.ts_id IS NULL
			OR	ISNULL(tst.completing_qty, 0) = 0
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN s.sketch_id IS NULL THEN 'Эскиза с кодом ' + CAST(ast.sketch_id AS VARCHAR(10)) + ' не существует. В строке номер ' + CAST(ast.rn AS VARCHAR(10))
	      	                   WHEN s.is_deleted = 1 THEN 'Эскиз с кодом ' + CAST(ast.sketch_id AS VARCHAR(10)) + ' удален. В строке номер ' + CAST(ast.rn AS VARCHAR(10))
	      	                   WHEN c.completing_id IS NULL THEN 'Комплектации с кодом ' + CAST(ast.completing_id AS VARCHAR(10)) +
	      	                        'не существует. в строке номер ' + CAST(ast.rn AS VARCHAR(10))
	      	                   WHEN ISNULL(ast.completing_number, 0) <= 0 THEN 'Не верный порядковый номер комплектации ' + CAST(ast.completing_number AS VARCHAR(10)) 
	      	                        + ' в строке номер ' + CAST(ast.rn AS VARCHAR(10))
	      	                   WHEN ISNULL(ast.consumption, 0) <= 0 THEN 'Не верно указан расход ' + CAST(ast.completing_number AS VARCHAR(10)) +
	      	                        ' в строке номер ' + CAST(ast.rn AS VARCHAR(10))
	      	                   WHEN oa.sketch_id IS NOT NULL THEN 'Эскиз с кодом ' + CAST(oa.sketch_id AS VARCHAR(10)) + ' выбран более одного раза.'
	      	                   WHEN  ast.sketch_id = @sketch_id THEN 'Базовый эскиз указан ещё и как дополнительный.'
	      	                   WHEN s.sketch_id IS NOT NULL AND oac.sketch_id IS NULL THEN 'У эскиз с артикулом ' + s.sa + ' не заполнена комплектация'
	      	                   WHEN s.sketch_id IS NOT NULL AND oac.consumption = 0 THEN 'У эскиз с артикулом ' + s.sa + ' не заполнен расход в комплектации'
	      	                   WHEN s.sketch_id IS NOT NULL AND oa_ts.sketch_id IS NULL THEN 'У эскиз с артикулом ' + s.sa + ' не указаны размеры раскладки'
	      	                   ELSE NULL
	      	              END
	FROM	@added_sketch_tab        ast   
			LEFT JOIN	Products.Sketch s
				ON                   ast.sketch_id = s.sketch_id   
			LEFT JOIN	Material.Completing c
				ON	c.completing_id = ast.completing_id   
			OUTER APPLY (
			      	SELECT	TOP(1) asto.sketch_id
			      	FROM	@added_sketch_tab asto
			      	WHERE	asto.sketch_id = ast.sketch_id
			      			AND	asto.rn != ast.rn
			      ) oa
			OUTER APPLY (
	      			SELECT	TOP(1) sc.sketch_id,
	      					ISNULL(sc.consumption, 0) consumption
	      			FROM	Products.SketchCompleting sc
	      			WHERE	sc.sketch_id = ast.sketch_id
	      			ORDER BY
	      				ISNULL(sc.consumption, 0)
				  )                             oac
			OUTER APPLY (
			      	SELECT TOP(1)	astts.sketch_id
			      	FROM	@added_sketch_tab_ts astts
			      	WHERE	astts.rn = ast.rn
			      			AND	astts.completing_qty > 0
			      ) oa_ts
	WHERE	s.sketch_id IS NULL
			OR	s.is_deleted = 1
			OR	c.completing_id IS NULL
			OR	ISNULL(ast.completing_number, 0) <= 0
			OR	ISNULL(ast.consumption, 0) <= 0
			OR	oa.sketch_id IS NOT NULL
			OR	ast.sketch_id = @sketch_id
			OR	oac.sketch_id IS NULL
			OR	oac.consumption = 0
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	INSERT INTO @added_spcv_tab
		(
			spcv_id
		)
	SELECT	ml.value('@id', 'int') spcv_id
	FROM	@added_spcv_xml.nodes('root/det')x(ml)
	
	SELECT	@error_text = CASE 
	      	                   WHEN spcv.spcv_id IS NULL THEN 'Цветоварианта с кодом ' + CAST(ast.spcv_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN spcv.spcv_id IS NOT NULL AND askt.sketch_id IS NULL THEN 'Цветоварианта с кодом ' + CAST(ast.spcv_id AS VARCHAR(10)) + ' (' 
	      	                        + an.art_name + '|' + s.sa + ') нет расхода в раскладке.'
	      	                   WHEN aspm.linked_spcv_id IS NOT NULL THEN 'Цветоварианта с кодом ' + CAST(ast.spcv_id AS VARCHAR(10)) + ' (' + an.art_name + '|' 
	      	                        + s.sa + '), уже является компаньеном другого цветоварианта'
	      	                   ELSE NULL
	      	              END
	FROM	@added_spcv_tab ast   
			LEFT JOIN	Planing.SketchPlanColorVariant spcv   
			INNER JOIN	Planing.SketchPlan sp   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = sp.sketch_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id
				ON	sp.sp_id = spcv.sp_id
				ON	spcv.spcv_id = ast.spcv_id   
			LEFT JOIN	@added_sketch_tab askt
				ON	askt.sketch_id = sp.sketch_id   
			LEFT JOIN	Planing.AddedSketchPlanMapping aspm
				ON	aspm.linked_spcv_id = spcv.spcv_id
				AND	aspm.base_spcv_id != @base_spcv_id
	WHERE	spcv.spcv_id IS NULL
			OR	askt.sketch_id IS NULL
			OR	aspm.linked_spcv_id IS NOT NULL
			
	
	BEGIN TRY
		BEGIN TRANSACTION 
		
		IF @layout_id IS NULL
		BEGIN
		    INSERT INTO Manufactory.Layout
		      (
		        create_dt,
		        create_employee_id,
		        dt,
		        employee_id,
		        frame_width,
		        layout_length,
		        effective_percent,
		        base_sketch_id,
		        base_completing_id,
		        base_completing_number,
		        base_consumption,
		        is_deleted,
		        comment
		      )OUTPUT	INSERTED.layout_id
		       INTO	@layout_output (
		       		layout_id
		       	)
		    VALUES
		      (
		        @dt,
		        @employee_id,
		        @dt,
		        @employee_id,
		        @frame_width,
		        @layout_length,
		        @effective_percent,
		        @sketch_id,
		        @completing_id,
		        @completing_number,
		        @consumption,
		        @is_deleted,
		        @comment
		      )
		    
		    
		    INSERT INTO Manufactory.TaskLayoutDetail
		      (
		        tl_id,
		        layout_id,
		        dt,
		        employee_id
		      )
		    SELECT	@tl_id,
		    		lo.layout_id,
		    		@dt,
		    		@employee_id
		    FROM	@layout_output lo
		    
		    INSERT INTO Manufactory.LayoutTS
		      (
		        layout_id,
		        ts_id,
		        completing_qty,
		        dt,
		        employee_id
		      )
		    SELECT	lo.layout_id,
		    		ts.ts_id,
		    		ts.completing_qty,
		    		@dt,
		    		@employee_id
		    FROM	@ts_tab ts   
		    		CROSS JOIN	@layout_output lo
		END
		ELSE
		BEGIN
		    UPDATE	Manufactory.Layout
		    SET 	dt                     = @dt,
		    		employee_id            = @employee_id,
		    		frame_width            = @frame_width,
		    		layout_length          = @layout_length,
		    		effective_percent      = @effective_percent,
		    		base_completing_id     = @completing_id,
		    		base_completing_number = @completing_number,
		    		base_consumption       = @consumption,
		    		is_deleted             = @is_deleted,
		    		comment                = @comment
		    		OUTPUT	INSERTED.layout_id
		    		INTO	@layout_output (
		    				layout_id
		    			)
		    WHERE	layout_id              = @layout_id
		    ; 
		    WITH cte_target AS (
		    	SELECT	lt.lts_id,
		    			lt.layout_id,
		    			lt.ts_id,
		    			lt.completing_qty,
		    			lt.dt,
		    			lt.employee_id
		    	FROM	Manufactory.LayoutTS lt
		    	WHERE EXISTS (
		    	     		SELECT	1
		    	     		FROM	@layout_output lo
		    	     		WHERE	lo.layout_id = lt.layout_id
		    	     	)
		    )			
		    MERGE cte_target t
		    USING (
		          	SELECT	lo.layout_id,
		          			ts.ts_id,
		          			ts.completing_qty,
		          			@dt              dt,
		          			@employee_id     employee_id
		          	FROM	@ts_tab ts   
		          			CROSS JOIN	@layout_output lo
		          ) s
		    		ON t.layout_id = s.layout_id
		    		AND t.ts_id = s.ts_id
		    WHEN MATCHED THEN 
		         UPDATE	
		         SET 	t.completing_qty = s.completing_qty,
		         		t.dt = s.dt,
		         		t.employee_id = s.employee_id
		    WHEN NOT MATCHED BY TARGET THEN 
		         INSERT
		         	(
		         		layout_id,
		         		ts_id,
		         		completing_qty,
		         		dt,
		         		employee_id
		         	)
		         VALUES
		         	(
		         		s.layout_id,
		         		s.ts_id,
		         		s.completing_qty,
		         		s.dt,
		         		s.employee_id
		         	)
		    WHEN NOT MATCHED BY SOURCE THEN 
		         DELETE	;
		END
		
		
		
		IF EXISTS(
		   	SELECT	1
		   	FROM	@added_sketch_tab
		   )
		BEGIN
		    ;WITH cte_target AS (
		    	SELECT	las.las_id,
		    			las.layout_id,
		    			las.sketch_id,
		    			las.completing_id,
		    			las.completing_number,
		    			las.consumption,
		    			las.dt,
		    			las.employee_id,
		    			las.is_deleted
		    	FROM	Manufactory.LayoutAddedSketch las   
		    			INNER JOIN	@layout_output lo
		    				ON	lo.layout_id = las.layout_id
		    )
		    MERGE cte_target t
		    USING (
		          	SELECT	lo.layout_id,
		          			ast.sketch_id,
		          			ast.completing_id,
		          			ast.completing_number,
		          			ast.consumption,
		          			@dt              dt,
		          			@employee_id     employee_id
		          	FROM	@added_sketch_tab ast   
		          			CROSS JOIN	@layout_output lo
		          ) s
		    		ON t.layout_id = s.layout_id
		    		AND t.sketch_id = s.sketch_id
		    		AND t.completing_id = s.completing_id
		    		AND t.completing_number = s.completing_number
		    WHEN MATCHED THEN 
		         UPDATE	
		         SET 	consumption     = s.consumption,
		         		dt              = s.dt,
		         		employee_id     = s.employee_id,
		         		is_deleted		= 0
		    WHEN NOT MATCHED BY TARGET THEN 
		         INSERT
		         	(
		         		layout_id,
		         		sketch_id,
		         		completing_id,
		         		completing_number,
		         		consumption,
		         		dt,
		         		employee_id
		         	)
		         VALUES
		         	(
		         		s.layout_id,
		         		s.sketch_id,
		         		s.completing_id,
		         		s.completing_number,
		         		s.consumption,
		         		s.dt,
		         		s.employee_id
		         	)
		    WHEN NOT MATCHED BY SOURCE THEN 
		         UPDATE 
		         SET	is_deleted		= 1 ,
						dt              = @dt,
		         		employee_id     = @employee_id
		              	OUTPUT	INSERTED.las_id,
		               			INSERTED.sketch_id,
		               			CASE WHEN s.layout_id IS NULL THEN 'D' ELSE LEFT($action, 1) END act,
		               			INSERTED.completing_id, 
		               			INSERTED.completing_number
		               	INTO	@layout_added_sketch_output (
		               			las_id,
		               			sketch_id,
		               			act,
		               			completing_id, 
		               			completing_number
		               		);
		    
		    
		    ;WITH cte_target AS (
		    	SELECT	lasts.lasts_id,
		    			lasts.las_id,
		    			lasts.ts_id,
		    			lasts.completing_qty,
		    			lasts.dt,
		    			lasts.employee_id
		    	FROM	Manufactory.LayoutAddedSketchTS lasts
		    	WHERE	EXISTS (
		    	     		SELECT	1
		    	     		FROM	@layout_added_sketch_output laso
		    	     		WHERE	laso.las_id = lasts.las_id
		    	     	)
		    )
		    MERGE cte_target t
		    USING (
		          	SELECT	laso.las_id,
							astt.ts_id,
							astt.completing_qty,
							@dt dt,
							@employee_id employee_id
					FROM	@added_sketch_tab_ts astt   
							INNER JOIN	@added_sketch_tab ast
								ON	ast.rn = astt.rn   
							INNER JOIN	@layout_added_sketch_output laso
								ON	laso.sketch_id = astt.sketch_id
								AND	laso.completing_id = ast.completing_id
								AND	laso.completing_number = ast.completing_number
		          ) s
		    		ON t.las_id = s.las_id
		    		AND t.ts_id = s.ts_id
		    WHEN MATCHED THEN 
		         UPDATE	
		         SET 	completing_qty     = s.completing_qty,
		         		dt                 = s.dt,
		         		employee_id        = s.employee_id		         		
		    WHEN NOT MATCHED BY TARGET THEN 
		         INSERT
		         	(
		         		las_id,
		         		ts_id,
		         		completing_qty,
		         		dt,
		         		employee_id
		         	)
		         VALUES
		         	(
		         		s.las_id,
		         		s.ts_id,
		         		s.completing_qty,
		         		s.dt,
		         		s.employee_id
		         	)
		    WHEN NOT MATCHED BY SOURCE THEN 
		         DELETE	;
		    
		    INSERT INTO Planing.SketchPlan
		      (
		        sketch_id,
		        ps_id,
		        create_employee_id,
		        create_dt,
		        employee_id,
		        dt,
		        comment,
		        qp_id,
				sew_fabricator_id
		      )OUTPUT	INSERTED.sp_id,
		       		INSERTED.sketch_id
		       INTO	@sketch_plan_output (
		       		sp_id,
		       		sketch_id
		       	)
		    SELECT	v.sketch_id,
		    		@status_add_as_compain,
		    		@employee_id,
		    		@dt,
		    		@employee_id,
		    		@dt,
		    		NULL,
		    		2,
					@sew_fabricator_id 
		    FROM	(SELECT	DISTINCT laso.sketch_id
		        	 FROM	@layout_added_sketch_output laso
		        	 WHERE	laso.act != 'D')v
		    WHERE	NOT EXISTS (
		         		SELECT	1
		         		FROM	Planing.SketchPlan sp   
		         				INNER JOIN	Planing.SketchPlanColorVariant spcv
		         					ON	spcv.sp_id = sp.sp_id   
		         				INNER JOIN	Planing.AddedSketchPlanMapping aspm
		         					ON	aspm.linked_spcv_id = spcv.spcv_id
		         		WHERE	sp.sketch_id = v.sketch_id
		         				AND	aspm.base_spcv_id = @base_spcv_id
		         	)
		    		AND	NOT EXISTS (
		    		   		SELECT	1
		    		   		FROM	@added_spcv_tab ast   
		    		   				INNER JOIN	Planing.SketchPlanColorVariant spcv
		    		   					ON	spcv.spcv_id = ast.spcv_id   
		    		   				INNER JOIN	Planing.SketchPlan sp
		    		   					ON	sp.sp_id = spcv.sp_id
		    		   		WHERE	sp.sketch_id = v.sketch_id
		    		   	)    
		    
		    UPDATE	spcv
		    SET 	is_deleted = 1,
		    		employee_id = @employee_id,
		    		dt = @dt
		    		OUTPUT	INSERTED.spcv_id,
						INSERTED.sp_id,
						INSERTED.spcv_name,
						INSERTED.cvs_id,
						INSERTED.qty,
						INSERTED.employee_id,
						INSERTED.dt,
						INSERTED.is_deleted,
						INSERTED.comment,
						INSERTED.pan_id,
						INSERTED.corrected_qty,
						INSERTED.begin_plan_delivery_dt,
						INSERTED.end_plan_delivery_dt,
						INSERTED.sew_office_id,
						INSERTED.sew_deadline_dt,
						INSERTED.cost_plan_year,
						INSERTED.cost_plan_month,
						@proc_id,
						INSERTED.sew_fabricator_id
				INTO	History.SketchPlanColorVariant (
						spcv_id,
						sp_id,
						spcv_name,
						cvs_id,
						qty,
						employee_id,
						dt,
						is_deleted,
						comment,
						pan_id,
						corrected_qty,
						begin_plan_delivery_dt,
						end_plan_delivery_dt,
						sew_office_id,
						sew_deadline_dt,
						cost_plan_year,
						cost_plan_month,
						proc_id,
						sew_fabricator_id
					)
		    FROM	Planing.SketchPlanColorVariant spcv
					INNER JOIN Planing.SketchPlan sp 
						ON sp.sp_id = spcv.sp_id
		    		INNER JOIN	Planing.AddedSketchPlanMapping aspm
		    			ON	aspm.linked_spcv_id = spcv.spcv_id
		    WHERE	aspm.base_spcv_id = @base_spcv_id
		    		AND	spcv.is_deleted = 0
		    		AND NOT EXISTS (SELECT	1
		    		                FROM	@layout_added_sketch_output laso
		    		                WHERE	laso.act != 'D'
		    								AND laso.sketch_id = sp.sketch_id
		    						)
		    
		    INSERT INTO Planing.SketchPlanColorVariant
		      (
		        sp_id,
		        spcv_name,
		        cvs_id,
		        qty,
		        employee_id,
		        dt,
		        is_deleted,
		        comment,
		        pan_id,
		        sew_office_id,
				sew_fabricator_id
		      )	OUTPUT	INSERTED.spcv_id,
		    				INSERTED.sp_id,
		    				INSERTED.spcv_name,
		    				INSERTED.cvs_id,
		    				INSERTED.qty,
		    				INSERTED.employee_id,
		    				INSERTED.dt,
		    				INSERTED.is_deleted,
		    				INSERTED.comment,
		    				INSERTED.pan_id,
		    				INSERTED.corrected_qty,
		    				INSERTED.begin_plan_delivery_dt,
		    				INSERTED.end_plan_delivery_dt,
		    				INSERTED.sew_office_id,
		    				INSERTED.sew_deadline_dt,
		    				INSERTED.cost_plan_year,
		    				INSERTED.cost_plan_month,
							INSERTED.sew_fabricator_id
		    		INTO	@spcv_output (
		    				spcv_id,
		    				sp_id,
		    				spcv_name,
		    				cvs_id,
		    				qty,
		    				employee_id,
		    				dt,
		    				is_deleted,
		    				comment,
		    				pan_id,
		    				corrected_qty,
		    				begin_plan_delivery_dt,
		    				end_plan_delivery_dt,
		    				sew_office_id,
		    				sew_deadline_dt,
		    				cost_plan_year,
		    				cost_plan_month,
							fabricator_id
		    		
		    			)
		    SELECT	spo.sp_id,
		    		'Компаньен',
		    		@cv_status_add_as_compain,
		    		0,
		    		@employee_id,
		    		@dt,
		    		0,
		    		NULL,
		    		NULL,
		    		@sew_office_id,
				    @sew_fabricator_id
		    FROM	@sketch_plan_output spo
			
		    
		    INSERT INTO History.SketchPlanColorVariant
		    	(
		    		spcv_id,
		    		sp_id,
		    		spcv_name,
		    		cvs_id,
		    		qty,
		    		employee_id,
		    		dt,
		    		is_deleted,
		    		comment,
		    		pan_id,
		    		corrected_qty,
		    		begin_plan_delivery_dt,
		    		end_plan_delivery_dt,
		    		sew_office_id,
		    		sew_deadline_dt,
		    		cost_plan_year,
		    		cost_plan_month,
		    		proc_id,
					sew_fabricator_id
		    	)
		    SELECT	sot.spcv_id,
		    		sot.sp_id,
		    		sot.spcv_name,
		    		sot.cvs_id,
		    		sot.qty,
		    		sot.employee_id,
		    		sot.dt,
		    		sot.is_deleted,
		    		sot.comment,
		    		sot.pan_id,
		    		sot.corrected_qty,
		    		sot.begin_plan_delivery_dt,
		    		sot.end_plan_delivery_dt,
		    		sot.sew_office_id,
		    		sot.sew_deadline_dt,
		    		sot.cost_plan_year,
		    		sot.cost_plan_month,
		    		@proc_id,
					fabricator_id
		    FROM	@spcv_output sot	
		    
		    INSERT INTO Planing.AddedSketchPlanMapping
		      (
		        base_spcv_id,
		        linked_spcv_id,
		        dt,
		        employee_id
		      )
		    SELECT	@base_spcv_id,
		    		so.spcv_id,
		    		@dt,
		    		@employee_id
		    FROM	@spcv_output so 
		    
		    INSERT INTO Planing.AddedSketchPlanMapping
		    	(
		    		base_spcv_id,
		    		linked_spcv_id,
		    		dt,
		    		employee_id
		    	) OUTPUT INSERTED.linked_spcv_id INTO @added_spcv_tab_out(spcv_id)
		    SELECT	@base_spcv_id,
		    		ast.spcv_id,
		    		@dt,
		    		@employee_id
		    FROM	@added_spcv_tab ast
		    WHERE	NOT EXISTS (
		         		SELECT	1
		         		FROM	Planing.AddedSketchPlanMapping aspm
		         		WHERE	aspm.linked_spcv_id = ast.spcv_id
		    )
		    
		    UPDATE	spcv
		    SET 	cvs_id = @cv_status_add_as_compain
		        	OUTPUT	INSERTED.spcv_id,
		        			INSERTED.sp_id,
		        			INSERTED.spcv_name,
		        			INSERTED.cvs_id,
		        			INSERTED.qty,
		        			INSERTED.employee_id,
		        			INSERTED.dt,
		        			INSERTED.is_deleted,
		        			INSERTED.comment,
		        			INSERTED.pan_id,
		        			INSERTED.corrected_qty,
		        			INSERTED.begin_plan_delivery_dt,
		        			INSERTED.end_plan_delivery_dt,
		        			INSERTED.sew_office_id,
		        			INSERTED.sew_deadline_dt,
		        			INSERTED.cost_plan_year,
		        			INSERTED.cost_plan_month,
		        			@proc_id,
							INSERTED.sew_fabricator_id
		        	INTO	History.SketchPlanColorVariant (
		        			spcv_id,
		        			sp_id,
		        			spcv_name,
		        			cvs_id,
		        			qty,
		        			employee_id,
		        			dt,
		        			is_deleted,
		        			comment,
		        			pan_id,
		        			corrected_qty,
		        			begin_plan_delivery_dt,
		        			end_plan_delivery_dt,
		        			sew_office_id,
		        			sew_deadline_dt,
		        			cost_plan_year,
		        			cost_plan_month,
		        			proc_id,
							sew_fabricator_id
		        		)
		    FROM	Planing.SketchPlanColorVariant spcv
		    		INNER JOIN	@added_spcv_tab_out asto
		    			ON	asto.spcv_id = spcv.spcv_id 
		    
		    INSERT INTO Planing.SketchPlanColorVariantCompleting
		      (
		        spcv_id,
		        completing_id,
		        completing_number,
		        rmt_id,
		        color_id,
		        frame_width,
		        okei_id,
		        consumption,
		        comment,
		        dt,
		        employee_id,
		        cs_id
		      )
		      OUTPUT	INSERTED.spcvc_id,
						INSERTED.spcv_id,
						INSERTED.completing_id,
						INSERTED.completing_number,
						INSERTED.rmt_id,
						INSERTED.color_id,
						INSERTED.frame_width,
						INSERTED.okei_id,
						INSERTED.consumption,
						INSERTED.comment,
						INSERTED.dt,
						INSERTED.employee_id,
						INSERTED.cs_id,
						@proc_id
				INTO	History.SketchPlanColorVariantCompleting (
						spcvc_id,
						spcv_id,
						completing_id,
						completing_number,
						rmt_id,
						color_id,
						frame_width,
						okei_id,
						consumption,
						comment,
						dt,
						employee_id,
						cs_id,
						proc_id
					)
		    SELECT	so.spcv_id,
		    		sc.completing_id,
		    		sc.completing_number,
		    		sc.base_rmt_id,
		    		0,
		    		sc.frame_width,
		    		sc.okei_id,
		    		sc.consumption,
		    		sc.comment,
		    		@dt,
		    		@employee_id,
		    		@cvc_state_covered_wh
		    FROM	@spcv_output so   
		    		INNER JOIN	@sketch_plan_output spo
		    			ON	spo.sp_id = so.sp_id   
		    		INNER JOIN	Products.SketchCompleting sc
		    			ON	sc.sketch_id = spo.sketch_id
		END
		
		COMMIT TRANSACTION
		
		SELECT	lo.layout_id
		FROM	@layout_output lo
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