CREATE PROCEDURE [Products].[SketchOld_Set_v2]
	@so_id INT = NULL,
	@brand_id INT,
	@st_id INT,
	@subject_id INT,
	@season_id INT,
	@model_year SMALLINT = NULL,
	@sa_local VARCHAR(15) = NULL,
	@sa VARCHAR(15) = NULL,
	@path_name VARCHAR(150) = NULL,
	@art_name VARCHAR(150) = NULL,
	@full_name VARCHAR(200) = NULL,
	@model_number INT = NULL,
	@employee_id INT,
	@is_deleted BIT = 0,
	@ct_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	
	IF @so_id IS NOT NULL
	   AND NOT EXISTS(
	       	SELECT	1
	       	FROM	Products.SketchOld so
	       	WHERE	so.so_id = @so_id
	       )
	BEGIN
	    RAISERROR('Эскиза с кодом %d не существует', 16, 1, @so_id)
	    RETURN
	END
	
	IF @brand_id IS NOT NULL
	   AND NOT EXISTS(
	       	SELECT	1
	       	FROM	Products.Brand b
	       	WHERE	b.brand_id = @brand_id
	       )
	BEGIN
	    RAISERROR('Бренда с кодом %d не существует', 16, 1, @brand_id)
	    RETURN
	END
	
	IF @st_id IS NOT NULL
	   AND NOT EXISTS(
	       	SELECT	1
	       	FROM	Products.SketchType st
	       	WHERE	st.st_id = @st_id
	       )
	BEGIN
	    RAISERROR('Типа с кодом %d не существует', 16, 1, @st_id)
	    RETURN
	END
	
	IF @subject_id IS NOT NULL
	   AND NOT EXISTS(
	       	SELECT	1
	       	FROM	Products.[Subject] s
	       	WHERE	s.subject_id = @subject_id
	       )
	BEGIN
	    RAISERROR('Предмета с кодом %d не существует', 16, 1, @subject_id)
	    RETURN
	END
	
	IF @season_id IS NOT NULL
	   AND NOT EXISTS(
	       	SELECT	1
	       	FROM	Products.Season s
	       	WHERE	s.season_id = @season_id
	       )
	BEGIN
	    RAISERROR('Предмета с кодом %d не существует', 16, 1, @season_id)
	    RETURN
	END
	
	IF @ct_id IS NOT NULL
	   AND NOT EXISTS(
	       	SELECT	1
	       	FROM	Material.ClothType ct
	       	WHERE	ct.ct_id = @ct_id
	       )
	BEGIN
	    RAISERROR('Типа ткани с кодом %d не существует', 16, 1, @ct_id)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION 
		;
		MERGE Products.SketchOld t
		USING (
		      	SELECT	@so_id            so_id,
		      			@brand_id         brand_id,
		      			@st_id            st_id,
		      			@subject_id       subject_id,
		      			@season_id        season_id,
		      			@model_year       model_year,
		      			@sa_local         sa_local,
		      			@sa               sa,
		      			@path_name        path_name,
		      			@art_name         art_name,
		      			@full_name        full_name,
		      			@model_number     model_number,
		      			@employee_id      employee_id,
		      			@dt               dt,
		      			@is_deleted       is_deleted,
		      			@ct_id            ct_id
		      ) s
				ON s.so_id = t.so_id
		WHEN  MATCHED  THEN 
		     UPDATE	
		     SET 	brand_id         = s.brand_id,
		     		st_id            = s.st_id,
		     		subject_id       = s.subject_id,
		     		season_id        = s.season_id,
		     		model_year       = ISNULL(s.model_year, t.model_year),
		     		sa_local         = ISNULL(s.sa_local, t.sa_local),
		     		sa               = ISNULL(s.sa, t.sa),
		     		path_name        = ISNULL(s.path_name, t.path_name),
		     		art_name         = ISNULL(s.art_name, t.art_name),
		     		full_name        = ISNULL(s.full_name, t.full_name),
		     		model_number     = ISNULL(s.model_number, t.model_number),
		     		employee_id      = s.employee_id,
		     		dt               = s.dt,
		     		is_deleted       = s.is_deleted,
		     		ct_id            = s.ct_id
		WHEN NOT MATCHED  THEN 
		     INSERT
		     	(
		     		brand_id,
		     		st_id,
		     		subject_id,
		     		season_id,
		     		model_year,
		     		sa_local,
		     		sa,
		     		path_name,
		     		art_name,
		     		full_name,
		     		model_number,
		     		employee_id,
		     		dt,
		     		is_deleted,
		     		ct_id
		     	)
		     VALUES
		     	(
		     		s.brand_id,
		     		s.st_id,
		     		s.subject_id,
		     		s.season_id,
		     		s.model_year,
		     		s.sa_local,
		     		s.sa,
		     		s.path_name,
		     		s.art_name,
		     		s.full_name,
		     		s.model_number,
		     		s.employee_id,
		     		s.dt,
		     		s.is_deleted,
		     		s.ct_id
		     	)
		     OUTPUT	INSERTED.so_id;
		
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