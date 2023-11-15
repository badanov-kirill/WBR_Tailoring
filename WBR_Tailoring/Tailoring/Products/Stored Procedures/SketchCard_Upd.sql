CREATE PROCEDURE [Products].[SketchCard_Upd]
	@sketch_id INT,
	@employee_id INT,
	@kind_id INT = NULL,
	@descr VARCHAR(1000) = NULL,
	@pic_count TINYINT = NULL,
	@tech_design BIT = NULL,
	@status_comment VARCHAR(250) = NULL,
	@qp_id TINYINT = NULL,
	@pattern_name VARCHAR(15) = NULL,
	@constructor_employee_id INT = NULL,
	@style_id INT = NULL,
	@ct_id INT = NULL,
	@wb_size_group_id INT = NULL,
	@content_list Products.ContentList READONLY,
	@tech_size_list dbo.List READONLY,
	@rv_bigint BIGINT,
	@is_deleted BIT,
	@tech_size_modify BIT = 1,
	@content_modify BIT = 1,
	@imt_name VARCHAR(100) = NULL,
	@sa VARCHAR(15) = NULL,
	@sa_local VARCHAR(15) = NULL,
	@model_year SMALLINT = NULL,
	@season_local_id INT = NULL,
	@plan_site_dt DATE = NULL,
	@is_china_sample BIT = 0,
	@construction_sale BIT = 0,
	@subject_id INT = NULL,
	@key_word VARCHAR(400) = NULL,
	@declaration_id INT = NULL
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @contents_tab TABLE (contents_id INT)
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @rv ROWVERSION = CAST(@rv_bigint AS ROWVERSION)
	DECLARE @with_log BIT = 1
	DECLARE @state_create TINYINT = 1 --Создан
	DECLARE @state_tech_design_approve TINYINT = 3 --Технический эскиз утвержден дизайнером	
	DECLARE @brand_id INT
	DECLARE @kw_id INT 
	
	DECLARE @sketch_output TABLE 
	        (
	        	sketch_id INT PRIMARY KEY CLUSTERED NOT NULL,
	        	is_deleted BIT NOT NULL,
	        	st_id TINYINT NOT NULL,
	        	ss_id TINYINT NOT NULL,
	        	pic_count TINYINT NOT NULL,
	        	tech_design BIT NOT NULL,
	        	kind_id INT NULL,
	        	subject_id INT NOT NULL,
	        	employee_id INT NOT NULL,
	        	dt dbo.SECONDSTIME NOT NULL,
	        	status_comment VARCHAR(250) NULL,
	        	qp_id TINYINT,
	        	model_year SMALLINT NULL,
	        	model_number INT NULL,
	        	brand_id INT NULL,
	        	season_id INT NULL,
	        	style_id INT NULL,
	        	wb_size_group_id INT NULL,
	        	art_name_id INT NULL,
	        	constructor_employee_id INT NULL,
	        	pattern_name VARCHAR(15) NULL,
	        	sa_local VARCHAR(15) NULL,
	        	sa VARCHAR(15) NULL,
	        	ct_id INT NULL,
	        	rv_bigint BIGINT,
	        	direction_id INT,
	        	imt_name VARCHAR(100),
	        	old_ss_id TINYINT,
	        	base_sketch_id INT,
	        	plan_site_dt DATE
	        )
	
	SELECT	@error_text = CASE 
	      	                   WHEN s.sketch_id IS NULL THEN 'Эскиза с номером ' + CAST(v.sketch_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN s.rv != @rv THEN 'Этот эскиз уже отреадактировал сотрудник с кодом' + CAST(s.employee_id AS VARCHAR(10)) + ' ' + CONVERT(VARCHAR(20), s.dt, 121) 
	      	                        +
	      	                        ', перечитайте данные и сохраните снова'
	      	                   ELSE NULL
	      	              END,
	      	@brand_id = s.brand_id
	FROM	(VALUES(@sketch_id))v(sketch_id)   
			LEFT JOIN	Products.Sketch s
				ON	s.sketch_id = v.sketch_id   
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	IF @kind_id IS NOT NULL
	   AND NOT EXISTS (
	       	SELECT	1
	       	FROM	Products.Kind k
	       	WHERE	k.kind_id = @kind_id
	       )
	BEGIN
	    RAISERROR('Пола с кодом %d не существует', 16, 1, @kind_id)
	    RETURN
	END
	
	IF @qp_id IS NOT NULL
	   AND NOT EXISTS (
	       	SELECT	1
	       	FROM	Products.QueuePriority qp
	       	WHERE	qp.qp_id = @qp_id
	       )
	BEGIN
	    RAISERROR('Приоритета с кодом %d не существует', 16, 1, @qp_id)
	    RETURN
	END
	
	IF @ct_id IS NOT NULL
	   AND NOT EXISTS (
	       	SELECT	1
	       	FROM	Material.ClothType ct
	       	WHERE	ct.ct_id = @ct_id
	       )
	BEGIN
	    RAISERROR('Ассортимента с кодом %d не существует', 16, 1, @ct_id)
	    RETURN
	END
	
	IF @style_id IS NOT NULL
	   AND NOT EXISTS (
	       	SELECT	1
	       	FROM	Products.Style s
	       	WHERE	s.style_id = @style_id
	       )
	BEGIN
	    RAISERROR('Стиля с кодом %d не существует', 16, 1, @style_id)
	    RETURN
	END
	
	IF @wb_size_group_id IS NOT NULL
	   AND NOT EXISTS(
	       	SELECT	1
	       	FROM	Products.WbSizeGroup wsg
	       	WHERE	wsg.wb_size_group_id = @wb_size_group_id
	       )
	BEGIN
	    RAISERROR('Группы размеров с кодом %d не существует', 16, 1, @wb_size_group_id)
	    RETURN
	END
	
	IF @model_year < (YEAR(@dt) - 10)
	   OR @model_year > (YEAR(@dt) + 3)
	BEGIN
	    RAISERROR('Некорректный год %d', 16, 1, @model_year)
	    RETURN
	END	
	
	IF @season_local_id IS NOT NULL
	   AND NOT EXISTS(
	       	SELECT	1
	       	FROM	Products.SeasonLocal sl
	       	WHERE	sl.season_local_id = @season_local_id
	       )
	BEGIN
	    RAISERROR('Сезона коллекции с кодом (%d) не существует', 16, 1, @season_local_id)
	    RETURN
	END
	
	SELECT	@error_text = 'Коллекцию ' + sl.season_local_name + ' ' + CAST(@model_year AS VARCHAR(10)) + ' бренда ' + b.brand_name 
	      	+ ' уже закрыл ' + ISNULL(es.employee_name, '') + ' , дата закрытия: ' + CONVERT(VARCHAR(20), cl.close_dt, 121) + ', копировать в неё нельзя.'
	FROM	Products.CollectionLocal cl   
			INNER JOIN	Products.SeasonLocal sl
				ON	sl.season_local_id = cl.season_local_id   
			INNER JOIN	Products.Brand b
				ON	b.brand_id = cl.brand_id   
			LEFT JOIN	Settings.EmployeeSetting es
				ON	es.employee_id = cl.close_employee_id
	WHERE	cl.season_model_year = @model_year
			AND	cl.season_local_id = @season_local_id
			AND	cl.close_dt IS NOT NULL
			AND	cl.brand_id = @brand_id
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN ts.ts_id IS NULL THEN 'Техразмера с кодом ' + CAST(tsl.id AS VARCHAR(10)) + ' не существует.'
	      	                   ELSE NULL
	      	              END
	FROM	@tech_size_list tsl   
			LEFT JOIN	Products.TechSize ts
				ON	ts.ts_id = tsl.id
	WHERE	ts.ts_id IS NULL
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN cl.contents_id IS NOT NULL AND c.contents_id IS NULL THEN 'Элемента комплекта с кодом ' + CAST(cl.contents_id AS VARCHAR(10)) 
	      	                        + ' не существует'
	      	                   WHEN cl.contents_id IS NOT NULL AND c.contents_name != cl.contents_name THEN 'Для элемента комплекта с кодом ' + CAST(cl.contents_id AS VARCHAR(10)) 
	      	                        + ' не соответствует наименование в справочнике (' + c.contents_name + ') и передаваемых данных - ' + cl.contents_name
	      	                   WHEN oac.cnt > 1 THEN 'Элемент комплекта с наименованием ' + cl.contents_name + ' указан более одного раза.'
	      	                   ELSE NULL
	      	              END
	FROM	@content_list cl   
			LEFT JOIN	Products.[Content] c
				ON	c.contents_id = cl.contents_id   
			OUTER APPLY (
			      	SELECT	COUNT(*) cnt
			      	FROM	@content_list clo
			      	WHERE	clo.contents_name = cl.contents_name
			      ) oac
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	INSERT INTO Products.Content
	  (
	    contents_name,
	    dt,
	    employee_id,
	    is_deleted
	  )
	SELECT	ct.contents_name,
			@dt               dt,
			@employee_id      employee_id,
			0                 is_deleted
	FROM	@content_list     ct
	WHERE	NOT EXISTS(
	     		SELECT	1
	     		FROM	Products.Content c
	     		WHERE	c.contents_name = ct.contents_name
	     	)
			AND	ct.contents_id IS NULL
	
	INSERT INTO @contents_tab
	  (
	    contents_id
	  )
	SELECT	cl.contents_id
	FROM	@content_list cl
	WHERE	cl.contents_id IS NOT NULL
	UNION
	SELECT	c.contents_id
	FROM	@content_list cl   
			INNER JOIN	Products.[Content] c
				ON	cl.contents_id IS NULL
				AND	c.contents_name = cl.contents_name
	
	IF NOT EXISTS (SELECT 1 FROM Products.[Subject] s WHERE s.subject_id = @subject_id)
	BEGIN
		RAISERROR('Предмета с кодом %d не существует',16,1,@subject_id)
		RETURN
	END
	
	IF @key_word IS NOT NULL
	BEGIN
		INSERT INTO Products.KeyWords
		(
			key_word
		)
		SELECT @key_word
		WHERE NOT EXISTS (SELECT 1 FROM Products.KeyWords kw WHERE kw.key_word = @key_word)
		
		SELECT @kw_id =kw.kw_id
		FROM Products.KeyWords kw
		WHERE kw.key_word = @key_word
	END
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		UPDATE	Products.Sketch
		SET 	is_deleted = ISNULL(@is_deleted, is_deleted),
				ss_id = CASE 
				             WHEN ss_id = @state_create AND @tech_design = 1 THEN @state_tech_design_approve
				             ELSE ss_id
				        END,
				pic_count = ISNULL(@pic_count, pic_count),
				tech_design = ISNULL(@tech_design, tech_design),
				kind_id = ISNULL(@kind_id, kind_id),
				descr = @descr,
				employee_id = @employee_id,
				dt = @dt,
				status_comment = CASE 
				                      WHEN @status_comment IS NULL THEN status_comment
				                      WHEN @status_comment = '' THEN NULL
				                      ELSE @status_comment
				                 END,
				qp_id = ISNULL(@qp_id, qp_id),
				style_id = ISNULL(@style_id, style_id),
				wb_size_group_id = ISNULL(@wb_size_group_id, wb_size_group_id),
				constructor_employee_id = @constructor_employee_id,
				pattern_name = ISNULL(@pattern_name, pattern_name),
				ct_id = ISNULL(@ct_id, ct_id),
				imt_name = @imt_name,
				sa = ISNULL(@sa, sa),
				sa_local = ISNULL(@sa_local, sa_local),
				season_model_year = ISNULL(@model_year, season_model_year),
				season_local_id = ISNULL(@season_local_id, season_local_id),
				plan_site_dt = ISNULL(@plan_site_dt, plan_site_dt),
				is_china_sample = @is_china_sample,
				subject_id = ISNULL(@subject_id, subject_id),
				kw_id = @kw_id
				OUTPUT	INSERTED.sketch_id,
						INSERTED.is_deleted,
						INSERTED.st_id,
						INSERTED.ss_id,
						INSERTED.pic_count,
						INSERTED.tech_design,
						INSERTED.kind_id,
						INSERTED.subject_id,
						INSERTED.employee_id,
						INSERTED.dt,
						INSERTED.status_comment,
						INSERTED.qp_id,
						INSERTED.model_year,
						INSERTED.model_number,
						INSERTED.brand_id,
						INSERTED.season_id,
						INSERTED.style_id,
						INSERTED.wb_size_group_id,
						INSERTED.art_name_id,
						INSERTED.constructor_employee_id,
						INSERTED.pattern_name,
						INSERTED.sa_local,
						INSERTED.sa,
						INSERTED.ct_id,
						CAST(INSERTED.rv AS BIGINT),
						INSERTED.direction_id,
						INSERTED.imt_name,
						DELETED.ss_id,
						INSERTED.base_sketch_id,
						INSERTED.plan_site_dt
				INTO	@sketch_output (
						sketch_id,
						is_deleted,
						st_id,
						ss_id,
						pic_count,
						tech_design,
						kind_id,
						subject_id,
						employee_id,
						dt,
						status_comment,
						qp_id,
						model_year,
						model_number,
						brand_id,
						season_id,
						style_id,
						wb_size_group_id,
						art_name_id,
						constructor_employee_id,
						pattern_name,
						sa_local,
						sa,
						ct_id,
						rv_bigint,
						direction_id,
						imt_name,
						old_ss_id,
						base_sketch_id,
						plan_site_dt
					)
		WHERE	sketch_id = @sketch_id
				AND	rv = @rv
		
		IF @@ROWCOUNT = 0
		BEGIN
		    SET @with_log = 0
		    RAISERROR('Кто то уже отредактировал данные, перечитайте и попробуйте снова', 16, 1)
		    RETURN
		END
				
		SELECT	@rv_bigint = so.rv_bigint
		FROM	@sketch_output so	
		
		IF @content_modify = 1
		BEGIN
		    ;
		    WITH cte_Target AS
		    (
		    	SELECT	sc.sketch_id,
		    			sc.contents_id
		    	FROM	Products.SketchContent sc
		    	WHERE	sc.sketch_id = @sketch_id
		    )
		    MERGE cte_Target t
		    USING @contents_tab s
		    		ON s.contents_id = t.contents_id
		    WHEN NOT MATCHED BY TARGET THEN 
		         INSERT
		         	(
		         		sketch_id,
		         		contents_id
		         	)
		         VALUES
		         	(
		         		@sketch_id,
		         		s.contents_id
		         	)
		    WHEN NOT MATCHED BY SOURCE THEN 
		         DELETE	;
		END
		
		IF @tech_size_modify = 1
		BEGIN
		    WITH cte_Target AS
		    (
		    	SELECT	sts.sketch_id,
		    			sts.ts_id
		    	FROM	Products.SketchTechSize sts
		    	WHERE	sts.sketch_id = @sketch_id
		    )
		    MERGE cte_Target t
		    USING @tech_size_list s
		    		ON s.id = t.ts_id
		    WHEN NOT MATCHED BY TARGET THEN 
		         INSERT
		         	(
		         		sketch_id,
		         		ts_id
		         	)
		         VALUES
		         	(
		         		@sketch_id,
		         		s.id
		         	)
		    WHEN NOT MATCHED BY SOURCE THEN 
		         DELETE	;
		END
		
		INSERT INTO History.Sketch
		  (
		    sketch_id,
		    is_deleted,
		    st_id,
		    pic_count,
		    tech_design,
		    kind_id,
		    subject_id,
		    employee_id,
		    qp_id,
		    dt,
		    model_year,
		    model_number,
		    brand_id,
		    season_id,
		    style_id,
		    wb_size_group_id,
		    art_name_id,
		    constructor_employee_id,
		    pattern_name,
		    sa_local,
		    sa,
		    ct_id,
		    direction_id,
		    imt_name,
		    base_sketch_id
		  )
		SELECT	so.sketch_id,
				so.is_deleted,
				so.st_id,
				so.pic_count,
				so.tech_design,
				so.kind_id,
				so.subject_id,
				so.employee_id,
				so.qp_id,
				so.dt,
				so.model_year,
				so.model_number,
				so.brand_id,
				so.season_id,
				so.style_id,
				so.wb_size_group_id,
				so.art_name_id,
				so.constructor_employee_id,
				so.pattern_name,
				so.sa_local,
				so.sa,
				so.ct_id,
				so.direction_id,
				so.imt_name,
				so.base_sketch_id
		FROM	@sketch_output so
		
		INSERT INTO History.SketchStatus
		  (
		    sketch_id,
		    ss_id,
		    employee_id,
		    dt,
		    status_comment,
		    plan_site_dt
		  )
		SELECT	so.sketch_id,
				so.ss_id,
				so.employee_id,
				so.dt,
				so.status_comment,
				so.plan_site_dt
		FROM	@sketch_output so
		WHERE so.ss_id != so.old_ss_id
		
		IF @season_local_id IS NOT NULL
		   AND @model_year IS NOT NULL
		BEGIN
		    MERGE Planing.SketchPrePlan t
		    USING (
		          	SELECT	@model_year     season_model_year,
		          			@season_local_id season_local_id,
		          			@sketch_id      sketch_id
		          ) s
		    		ON s.season_model_year = t.season_model_year
		    		AND s.season_local_id = t.season_local_id
		    		AND s.sketch_id = t.sketch_id
			WHEN MATCHED AND t.spps_id = 3 THEN 
				UPDATE 
				SET spps_id = 1,
					employee_id = @employee_id,
					dt = @dt
		    WHEN NOT MATCHED THEN 
		         INSERT
		         	(
		         		season_model_year,
		         		season_local_id,
		         		sketch_id,
		         		spps_id,
		         		create_employee_id,
		         		create_dt,
		         		employee_id,
		         		dt,
		         		sale_plan_dt,
		         		plan_dt,
		         		buy_material_plan_dt,
		         		sew_office_id,
		         		plan_qty,
		         		cv_qty
		         	)
		         VALUES
		         	(
		         		s.season_model_year,
		         		s.season_local_id,
		         		s.sketch_id,
		         		1,
		         		@employee_id,
		         		@dt,
		         		@employee_id,
		         		@dt,
		         		NULL,
		         		@plan_site_dt,
		         		NULL,
		         		NULL,
		         		NULL,
		         		NULL
		         	);
		    
		    
		    INSERT INTO Products.CollectionLocal
		    	(
		    		season_model_year,
		    		season_local_id,
		    		brand_id
		    	)
		    SELECT	@model_year,
		    		@season_local_id,
		    		@brand_id
		    WHERE	NOT EXISTS (
		         		SELECT	1
		         		FROM	Products.CollectionLocal cl
		         		WHERE	cl.season_model_year = @model_year
		         				AND	cl.season_local_id = @season_local_id
		         				AND	cl.brand_id = @brand_id
		         	)
		    
		END
		
		IF @construction_sale = 1
		BEGIN
		    INSERT INTO Products.SketchConstructionSale
		    	(
		    		sketch_id,
		    		dt,
		    		employee_id
		    	)
		    SELECT	@sketch_id,
		    		@dt,
		    		@employee_id
		    WHERE	NOT EXISTS (
		         		SELECT	1
		         		FROM	Products.SketchConstructionSale scs
		         		WHERE	scs.sketch_id = @sketch_id
		         	)
		END
		ELSE
		BEGIN
		    DELETE	
		    FROM	Products.SketchConstructionSale
		    WHERE	sketch_id = @sketch_id
		END;	
		
		COMMIT TRANSACTION
		
		SELECT	@sketch_id     sketch_id,
				@rv_bigint     rv_bigint
		
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