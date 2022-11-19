CREATE PROCEDURE [Products].[SketchCard_AddOnBasisOf]
	@base_sketch_id INT,
	@employee_id INT,
	@art_name VARCHAR(100),
	@qp_id TINYINT,
	@brand_id INT,
	@constructor_employee_id INT = NULL,
	@comment VARCHAR(200)
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @st_id INT
	DECLARE @kind_id INT
	DECLARE @subject_id INT
	DECLARE @descr VARCHAR(1000)
	DECLARE @pic_count TINYINT
	DECLARE @tech_design BIT
	DECLARE @status_comment VARCHAR(250) 
	DECLARE @season_id INT
	DECLARE @model_year SMALLINT = YEAR(@dt)
	DECLARE @ct_id INT
	DECLARE @direction_id INT 
	DECLARE @imt_name VARCHAR(100)
	DECLARE @sketch_id INT
	DECLARE @rv_bigint BIGINT
	DECLARE @status_id INT = 1
	DECLARE @is_deleted BIT = 0
	DECLARE @pa_id INT
	DECLARE @kw_id INT
	declare @artpostfix varchar(1) = 'н'
	
	DECLARE @art_name_output TABLE(art_name_id INT)
	DECLARE @art_name_id INT
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @season_art CHAR(1)
	DECLARE @with_log BIT = 1
	DECLARE @sa VARCHAR(15)
	
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
	        	base_sketch_id INT
	        )
	
	DECLARE @prod_aricle_output TABLE 
	        (
	        	pa_id INT PRIMARY KEY CLUSTERED NOT NULL,
	        	sketch_id INT NOT NULL,
	        	is_deleted BIT NOT NULL,
	        	model_number INT NOT NULL,
	        	descr VARCHAR(1000) NULL,
	        	brand_id INT NOT NULL,
	        	season_id INT NULL,
	        	collection_id INT NULL,
	        	style_id INT NULL,
	        	direction_id INT NULL,
	        	employee_id INT NOT NULL,
	        	dt dbo.SECONDSTIME NOT NULL,
	        	ao_ts_id INT,
	        	is_not_new BIT
	        )        	
	
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
	
	SELECT	@error_text = CASE 
	      	                   WHEN s.sketch_id IS NULL THEN 'Эскиза с номером ' + CAST(v.sketch_id AS VARCHAR(10)) + ' не существует'
	      	                   ELSE NULL
	      	              END,
			@st_id                       = s.st_id,
			@kind_id                     = s.kind_id,
			@subject_id                  = s.subject_id,
			@descr                       = s.descr,
			@pic_count                   = CASE 
			                  WHEN s.pic_count > 0 THEN 1
			                  ELSE 0
			             END,
			@tech_design                 = s.tech_design,
			@status_comment              = 'Создан на основании ' + s.sa_local + '|' + @comment,
			@season_id                   = s.season_id,
			@constructor_employee_id     = s.constructor_employee_id,
			@ct_id                       = s.ct_id,
			@direction_id                = s.direction_id,
			@imt_name                    = s.imt_name,
			@season_art                  = LEFT(sn.season_name, 1),
			@pa_id                       = oa_pa.pa_id,
			@kw_id						 = s.kw_id
	FROM	(VALUES(@base_sketch_id))v(sketch_id)   
			LEFT JOIN	Products.Sketch s   
			INNER JOIN	Products.Season sn
				ON	sn.season_id = s.season_id
				ON	s.sketch_id = v.sketch_id   
			OUTER APPLY (
			      	SELECT	TOP(1) pa.pa_id
			      	FROM	Products.ProdArticle pa
			      	WHERE	pa.sketch_id = s.sketch_id
			      			AND	pa.is_deleted = 0
			      	ORDER BY
			      		pa.pa_id DESC
			      ) oa_pa
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END	
	
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
		    sa_local,
		    sa,
		    ct_id,
		    direction_id,
		    imt_name,
		    base_sketch_id,
		    kw_id,
		    art_year
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
		   		INSERTED.base_sketch_id
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
		   		base_sketch_id,
				artpostfix
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
				Products.ArticleGet(@brand_id, @st_id, vt.model_number, @model_year, @season_art, @artpostfix),
				Products.ArticleGet_v2(@brand_id, @st_id, vt.model_number, @model_year, @season_art, @direction_id, @artpostfix),
				@ct_id,
				@direction_id,
				@imt_name,
				@base_sketch_id,
				@kw_id,
				@model_year,
				@artpostfix
		FROM	(SELECT	ISNULL(MAX(s.model_number) + 1, 200) model_number
		    	 FROM	Products.Sketch s
		    	 WHERE	s.brand_id = @brand_id
		    	 		AND	s.st_id = @st_id
		    	 		AND	s.art_year = @model_year
		    	 		AND	s.season_id = @season_id
		    	 		AND	s.model_number >= 200)vt		
		
		SELECT	@sketch_id = so.sketch_id,
				@rv_bigint     = so.rv_bigint,
				@sa            = so.sa
		FROM	@sketch_output so		
		
		INSERT INTO Products.SketchContent
		  (
		    sketch_id,
		    contents_id
		  )
		SELECT	@sketch_id,
				sc.contents_id
		FROM	Products.SketchContent sc
		WHERE	sc.sketch_id = @base_sketch_id
		
		INSERT INTO Products.SketchTechSize
		  (
		    sketch_id,
		    ts_id
		  )
		SELECT	@sketch_id,
				sts.ts_id
		FROM	Products.SketchTechSize sts
		WHERE	sts.sketch_id = @base_sketch_id
		
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
		    status_comment
		  )
		SELECT	so.sketch_id,
				so.ss_id,
				so.employee_id,
				so.dt,
				so.status_comment
		FROM	@sketch_output so
		
		IF @pa_id IS NOT NULL
		BEGIN
		    INSERT INTO Products.ProdArticle
		      (
		        sketch_id,
		        is_deleted,
		        model_number,
		        descr,
		        brand_id,
		        season_id,
		        collection_id,
		        style_id,
		        direction_id,
		        create_employee_id,
		        create_dt,
		        employee_id,
		        dt,
		        ao_ts_id,
		        imt_id,
		        is_not_new,
		        sa
		      )OUTPUT	INSERTED.pa_id,
		       		INSERTED.sketch_id,
		       		INSERTED.is_deleted,
		       		INSERTED.model_number,
		       		INSERTED.brand_id,
		       		INSERTED.season_id,
		       		INSERTED.collection_id,
		       		INSERTED.style_id,
		       		INSERTED.direction_id,
		       		INSERTED.employee_id,
		       		INSERTED.dt,
		       		INSERTED.ao_ts_id,
		       		INSERTED.is_not_new
		       INTO	@prod_aricle_output (
		       		pa_id,
		       		sketch_id,
		       		is_deleted,
		       		model_number,
		       		brand_id,
		       		season_id,
		       		collection_id,
		       		style_id,
		       		direction_id,
		       		employee_id,
		       		dt,
		       		ao_ts_id,
		       		is_not_new
		       	)
		    SELECT	@sketch_id,
		    		@is_deleted,
		    		1,
		    		NULL,
		    		@brand_id,
		    		@season_id,
		    		pa.collection_id,
		    		pa.style_id,
		    		NULL,
		    		@employee_id,
		    		@dt,
		    		@employee_id,
		    		@dt,
		    		pa.ao_ts_id,
		    		NULL,
		    		0,
		    		@sa + '1/'
		    FROM	Products.ProdArticle pa
		    WHERE	pa.pa_id = @pa_id
		    
		    INSERT INTO History.ProdArticle
		      (
		        pa_id,
		        sketch_id,
		        is_deleted,
		        model_number,
		        brand_id,
		        season_id,
		        collection_id,
		        style_id,
		        direction_id,
		        employee_id,
		        dt,
		        ao_ts_id,
		        is_not_new
		      )
		    SELECT	pao.pa_id,
		    		pao.sketch_id,
		    		pao.is_deleted,
		    		pao.model_number,
		    		pao.brand_id,
		    		pao.season_id,
		    		pao.collection_id,
		    		pao.style_id,
		    		pao.direction_id,
		    		pao.employee_id,
		    		pao.dt,
		    		pao.ao_ts_id,
		    		pao.is_not_new
		    FROM	@prod_aricle_output pao;
		    
		    INSERT INTO Products.ProdArticleAddedOption
		      (
		        pa_id,
		        ao_id,
		        employee_id,
		        dt,
		        ao_value,
		        si_id
		      )
		    SELECT	pao.pa_id,
		    		paao.ao_id,
		    		@employee_id,
		    		@dt,
		    		paao.ao_value,
		    		paao.si_id
		    FROM	Products.ProdArticleAddedOption paao   
		    		CROSS JOIN	@prod_aricle_output pao
		    WHERE	paao.pa_id = @pa_id
		END
		
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