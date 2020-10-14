CREATE PROCEDURE [Products].[SketchCard_Add]
	@employee_id INT,
	@st_id INT,
	@kind_id INT,
	@subject_id INT,
	@descr VARCHAR(1000),
	@pic_count TINYINT,
	@tech_design BIT,
	@status_comment VARCHAR(250) = NULL,
	@qp_id TINYINT,
	@brand_id INT,
	@season_id INT,
	@pattern_name VARCHAR(15) = NULL,
	@model_year SMALLINT,
	@art_name VARCHAR(100),
	@constructor_employee_id INT = NULL,
	@ct_id INT,
	@content_list Products.ContentList READONLY,
	@tech_size_list dbo.List READONLY,
	@direction_id INT = NULL,
	@imt_name VARCHAR(100) = NULL,
	@season_local_id INT = NULL,
	@plan_site_dt DATE = NULL,
	@is_china_sample BIT = 0
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	DECLARE @sketch_id INT
	DECLARE @rv_bigint BIGINT
	DECLARE @status_id INT = 1
	DECLARE @is_deleted BIT = 0
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @art_name_output TABLE(art_name_id INT)
	DECLARE @art_name_id INT
	DECLARE @contents_tab TABLE (contents_id INT)
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @season_art CHAR(1)
	DECLARE @with_log BIT = 1
	
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
	        	plan_site_dt DATE
	        )
	
	IF @plan_site_dt IS NULL 
	BEGIN
		RAISERROR('Не указана дата сайт', 16, 1)
	    RETURN
	END
	
	IF ISNULL(@art_name, '') = ''
	BEGIN
	    RAISERROR('Не указано худ. название', 16, 1)
	    RETURN
	END
	
	IF EXISTS (
	   	SELECT	1
	   	FROM	Products.ArtName an
	   	WHERE	an.art_name = @art_name
	   )
	BEGIN
	    RAISERROR('Худ. название уже используется', 16, 1)
	    RETURN
	END
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Products.SketchType st
	   	WHERE	st.st_id = @st_id
	   )
	BEGIN
	    RAISERROR('Типа эскиза (%d) не существует', 16, 1, @st_id)
	    RETURN
	END
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Products.Kind k
	   	WHERE	k.kind_id = @kind_id
	   )
	BEGIN
	    RAISERROR('Пола с кодом (%d) не существует', 16, 1, @kind_id)
	    RETURN
	END
	
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Products.[Subject] s
	   	WHERE	s.subject_id = @subject_id
	   )
	BEGIN
	    RAISERROR('Предмета с кодом (%d) не существует', 16, 1, @subject_id)
	    RETURN
	END
	
	IF NOT EXISTS(
	   	SELECT	1
	   	FROM	Products.QueuePriority qp
	   	WHERE	qp.qp_id = @qp_id
	   )
	BEGIN
	    RAISERROR('Приоритетности с кодом (%d) не существует', 16, 1, @qp_id)
	    RETURN
	END
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Products.Brand b
	   	WHERE	b.brand_id = @brand_id
	   )
	BEGIN
	    RAISERROR('Бренда с кодом (%d) не существует', 16, 1, @brand_id)
	    RETURN
	END	
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Material.ClothType ct
	   	WHERE	ct.ct_id = @ct_id
	   )
	BEGIN
	    RAISERROR('Типа ткани с кодом (%d) не существует', 16, 1, @ct_id)
	    RETURN
	END
	
	SELECT	@season_art = LEFT(s.season_name, 1)
	FROM	Products.Season s
	WHERE	s.season_id = @season_id
	
	IF @season_art IS NULL
	BEGIN
	    RAISERROR('Сезона с кодом (%d) не существует', 16, 1, @season_id)
	    RETURN
	END
	
	IF @direction_id IS NOT NULL AND
	NOT EXISTS(SELECT 1 FROM Products.Direction d WHERE d.direction_id = @direction_id)
	BEGIN
	    RAISERROR('Направления с кодом (%d) не существует', 16, 1, @direction_id)
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
	
	IF @model_year < (YEAR(@dt) - 3)
	   OR @model_year > (YEAR(@dt) + 3)
	BEGIN
	    RAISERROR('Некорректный год %d', 16, 1, @model_year)
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
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		INSERT INTO Products.ArtName
		  (
		    art_name,
		    employee_id,
		    dt
		  )OUTPUT	INSERTED.art_name_id
		   INTO	@art_name_output (
		   		art_name_id
		   	)
		SELECT	@art_name,
				@employee_id,
				@dt
		WHERE	NOT EXISTS (
		     		SELECT	1
		     		FROM	Products.ArtName an
		     		WHERE	an.art_name = @art_name
		     	)
		
		
		SELECT	@art_name_id = ano.art_name_id
		FROM	@art_name_output ano
		
		IF @art_name_id IS NULL
		BEGIN
		    SET @with_log = 0
		    RAISERROR('Худ. название уже используется', 16, 1)
		    RETURN
		END 
		
		INSERT INTO Products.Sketch
		  (
		    is_deleted,
		    st_id,
		    ss_id,
		    pic_count,
		    tech_design,
		    kind_id,
		    subject_id,
		    descr,
		    create_employee_id,
		    create_dt,
		    employee_id,
		    dt,
		    status_comment,
		    qp_id,
		    model_year,
		    model_number,
		    brand_id,
		    season_id,
		    art_name_id,
		    constructor_employee_id,
		    pattern_name,
		    sa_local,
		    sa,
		    ct_id,
		    direction_id,
		    imt_name,
		    season_model_year, 
		    season_local_id,
		    plan_site_dt,
		    is_china_sample	    
		  )OUTPUT	INSERTED.sketch_id,
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
		   		plan_site_dt
		   	)
		SELECT	@is_deleted,
				@st_id,
				@status_id,
				@pic_count,
				@tech_design,
				@kind_id,
				@subject_id,
				@descr,
				@employee_id,
				@dt,
				@employee_id,
				@dt,
				@status_comment,
				@qp_id,
				@model_year,
				vt.model_number,
				@brand_id,
				@season_id,
				@art_name_id,
				@constructor_employee_id,
				@pattern_name,
				Products.ArticleGet(@brand_id, @st_id, vt.model_number, @model_year, @season_art),
				Products.ArticleGet_v2(@brand_id, @st_id, vt.model_number, @model_year, @season_art, @direction_id),
				@ct_id,
				@direction_id,
				@imt_name,
				@model_year,
				@season_local_id,
				@plan_site_dt,
				@is_china_sample
		FROM	(SELECT	ISNULL(MAX(s.model_number) + 1, 200) model_number
		    	 FROM	Products.Sketch s
		    	 WHERE	s.brand_id = @brand_id
		    	 		AND	s.st_id = @st_id
		    	 		AND	s.model_year = @model_year
		    	 		AND	s.season_id = @season_id
						AND s.model_number >= 200)vt		
		
		SELECT	@sketch_id = so.sketch_id,
				@rv_bigint = so.rv_bigint
		FROM	@sketch_output so		
		
		INSERT INTO Products.SketchContent
		  (
		    sketch_id,
		    contents_id
		  )
		SELECT	@sketch_id        sketch_id,
				ct.contents_id
		FROM	@contents_tab     ct
		
		INSERT INTO Products.SketchTechSize
		  (
		    sketch_id,
		    ts_id
		  )
		SELECT	@sketch_id          sketch_id,
				ts.id               ts_id
		FROM	@tech_size_list     ts 
		
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
		    imt_name
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
				so.imt_name
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
		
		IF @season_local_id IS NOT NULL
		BEGIN
		    INSERT INTO Planing.SketchPrePlan
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
		    		@model_year,
		    		@season_local_id,
		    		@sketch_id,
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
		    	)
		    	
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
		
		COMMIT TRANSACTION

		SELECT	@sketch_id     sketch_id,
				@rv_bigint      rv_bigint

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