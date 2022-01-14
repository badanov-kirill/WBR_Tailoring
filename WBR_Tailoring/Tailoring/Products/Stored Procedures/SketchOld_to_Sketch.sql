CREATE PROCEDURE [Products].[SketchOld_to_Sketch]
	@so_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @st_id INT
	DECLARE @brand_id INT
	DECLARE @model_year SMALLINT
	DECLARE @model_number INT
	DECLARE @sa VARCHAR(15)
	DECLARE @sa_local VARCHAR(15)
	DECLARE @subject_id INT
	DECLARE @ct_id INT
	DECLARE @season_id INT
	DECLARE @art_name VARCHAR(150)
	DECLARE @art_name_id INT
	DECLARE @sketch_id INT
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @ss_id INT = 3
	DECLARE @qp_id TINYINT = 3
	
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
	        	direction_id INT NULL
	        )
	
	SELECT	@brand_id = so.brand_id,
			@st_id            = so.st_id,
			@subject_id       = so.subject_id,
			@season_id        = so.season_id,
			@model_year       = so.model_year,
			@sa               = so.sa,
			@sa_local         = so.sa_local,
			@art_name         = so.art_name,
			@model_number     = so.model_number,
			@ct_id            = so.ct_id
	FROM	Products.SketchOld so
	WHERE	so.so_id = @so_id
	
	IF @@ROWCOUNT = 0
	BEGIN
	    RAISERROR('Эскиза с таким кодом %d не существует', 16, 1, @so_id)
	    RETURN
	END
	
	IF @brand_id IS NULL
	BEGIN
	    RAISERROR('У эскиза не заполнен бренд', 16, 1)
	    RETURN
	END
	
	IF @st_id IS NULL
	BEGIN
	    RAISERROR('У эскиза не заполнен ассортимент', 16, 1)
	    RETURN
	END
	
	IF @subject_id IS NULL
	BEGIN
	    RAISERROR('У эскиза не заполнен предмет', 16, 1)
	    RETURN
	END	
	
	IF @season_id IS NULL
	BEGIN
	    RAISERROR('У эскиза не заполнен сезон', 16, 1)
	    RETURN
	END
	
	IF ISNULL(@sa, '') = ''
	BEGIN
	    RAISERROR('У эскиза не заполнен артикул', 16, 1)
	    RETURN
	END
	
	IF ISNULL(@sa_local, '') = ''
	BEGIN
	    RAISERROR('У эскиза не заполнен внутр. артикул', 16, 1)
	    RETURN
	END
	
	IF ISNULL(@art_name, '') = ''
	BEGIN
	    RAISERROR('У эскиза не заполнено худ. название', 16, 1)
	    RETURN
	END
	
	IF ISNULL(@model_number, 0) = 0
	BEGIN
	    RAISERROR('У эскиза не заполнен порядковый номер', 16, 1)
	    RETURN
	END		
	
	INSERT INTO Products.ArtName
	  (
	    art_name,
	    employee_id,
	    dt
	  )
	SELECT	@art_name,
			@employee_id,
			@dt
	WHERE	NOT EXISTS (
	     		SELECT	1
	     		FROM	Products.ArtName an
	     		WHERE	an.art_name = @art_name
	     	)
	
	SELECT	@art_name_id = an.art_name_id
	FROM	Products.ArtName an
	WHERE	an.art_name = @art_name
	
	
	
	SELECT	@error_text = CASE 
	      	                   WHEN @art_name_id = s.art_name_id AND s.is_deleted = 0 THEN 'Художественное название ' + @art_name +
	      	                        ' уже использовано в новом артикуле ' + s.sa_local + ' эскиз номер ' + CAST(s.sketch_id AS VARCHAR(10))
	      	                   WHEN s.model_year = @model_year AND s.model_number = @model_number AND s.brand_id = @brand_id AND s.st_id = @st_id AND s.season_id 
	      	                        = @season_id AND s.is_deleted = 0 THEN 'Артикул с такими параметрами уже существует, его худ.название ' + an.art_name +
	      	                        ' номер эскиза ' + CAST(s.sketch_id AS VARCHAR(10))
	      	                   WHEN s.art_year = @model_year AND s.model_number = @model_number AND s.brand_id = @brand_id AND s.st_id = @st_id AND s.season_id 
	      	                        = @season_id AND s.is_deleted = 1 AND @art_name_id != s.art_name_id THEN 
	      	                        'Артикул с такими параметрами и другим худ.названием уже существует, его худ.название ' + an.art_name +
	      	                        ' номер эскиза ' + CAST(s.sketch_id AS VARCHAR(10))
	      	                   ELSE NULL
	      	              END,
			@sketch_id = s.sketch_id
	FROM	Products.Sketch s   
			LEFT JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id
	WHERE	(s.model_year = @model_year AND s.model_number = @model_number AND s.brand_id = @brand_id AND s.st_id = @st_id AND s.season_id = @season_id)
			OR	s.art_name_id = @art_name_id
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	IF @sketch_id IS NOT NULL
	BEGIN
	    SELECT	@sketch_id     sketch_id,
	    		@so_id         so_id
	    
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION		
		
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
		   		INSERTED.direction_id
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
		   		direction_id		   		
		   	)
		VALUES
		  (
		    1,
		    @st_id,
		    @ss_id,
		    1,
		    1,
		    NULL,
		    @subject_id,
		    NULL,
		    @employee_id,
		    @dt,
		    @employee_id,
		    @dt,
		    NULL,
		    @qp_id,
		    @model_year,
		    @model_number,
		    @brand_id,
		    @season_id,
		    @art_name_id,
		    NULL,
		    NULL,
		    @sa_local,
		    @sa,
		    @ct_id,
		    NULL,
		    @model_year
		  ) 
		
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
		    direction_id
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
				so.direction_id
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
		
		SELECT	@sketch_id = so.sketch_id
		FROM	@sketch_output so	
		
		INSERT INTO Products.SketchBranchOfficePattern
		  (
		    sketch_id,
		    office_id,
		    employee_id,
		    dt
		  )
		SELECT	@sketch_id,
				sobop.office_id,
				sobop.employee_id,
				sobop.dt
		FROM	Products.SketchOldBranchOfficePattern sobop
		WHERE	sobop.so_id = @so_id
		
		COMMIT TRANSACTION
		
		SELECT	@sketch_id     sketch_id,
				@so_id         so_id
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