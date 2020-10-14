CREATE PROCEDURE [Products].[ArticleForPreBudget_Get_v2]
	@brand_id INT = NULL,
	@st_id INT = NULL,
	@subject_id INT = NULL,
	@season_id INT = NULL,
	@model_year SMALLINT = NULL,
	@sa_local VARCHAR(15) = NULL,
	@sa VARCHAR(15) = NULL,
	@art_name VARCHAR(150) = NULL,
	@full_name VARCHAR(200) = NULL,
	@pattern_office_id INT = NULL,
	@ct_id INT = NULL,
	@is_deleted BIT = 0,
	@is_new BIT = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	so.so_id
	INTO	#t
	FROM	Products.SketchOld so
	WHERE	(@brand_id IS NULL OR so.brand_id = @brand_id)
			AND	(@st_id IS NULL OR so.st_id = @st_id)
			AND	(@subject_id IS NULL OR so.subject_id = @subject_id)
			AND	(@season_id IS NULL OR so.season_id = @season_id)
			AND	(@model_year IS NULL OR so.model_year = @model_year)
			AND	(@sa_local IS NULL OR so.sa_local = @sa_local)
			AND	(@sa IS NULL OR so.sa = @sa)
			AND	(@art_name IS NULL OR so.art_name LIKE '%' + @art_name + '%')
			AND	(@full_name IS NULL OR so.full_name LIKE '%' + @full_name + '%')
			AND	(@is_deleted IS NULL OR so.is_deleted = @is_deleted)
			AND	(@ct_id IS NULL OR so.ct_id = @ct_id)
			AND	(@is_new IS NULL OR @is_new = 0)
			AND	(
			   		@pattern_office_id IS NULL
			   		OR EXISTS(
			   		   	SELECT	1
			   		   	FROM	Products.SketchOldBranchOfficePattern sobop
			   		   	WHERE	sobop.so_id = so.so_id
			   		   			AND	sobop.office_id = @pattern_office_id
			   		   )
			   	)
	
	
	SELECT	s.sketch_id
	INTO	#tt
	FROM	Products.Sketch s   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id
	WHERE	(@brand_id IS NULL OR s.brand_id = @brand_id)
			AND	(@st_id IS NULL OR s.st_id = @st_id)
			AND	(@subject_id IS NULL OR s.subject_id = @subject_id)
			AND	(@season_id IS NULL OR s.season_id = @season_id)
			AND	(@model_year IS NULL OR s.model_year = @model_year)
			AND	(@sa_local IS NULL OR s.sa_local = @sa_local)
			AND	(@sa IS NULL OR s.sa = @sa)
			AND	(@art_name IS NULL OR an.art_name LIKE '%' + @art_name + '%')
			AND	(@is_deleted IS NULL OR s.is_deleted = @is_deleted)
			AND	(@ct_id IS NULL OR s.ct_id = @ct_id)
			AND	(@is_new IS NULL OR @is_new = 1)
			AND	(
			   		@pattern_office_id IS NULL
			   		OR EXISTS(
			   		   	SELECT	1
			   		   	FROM	Products.SketchBranchOfficePattern sbop
			   		   	WHERE	sbop.sketch_id = s.sketch_id
			   		   			AND	sbop.office_id = @pattern_office_id
			   		   )
			   	)
	
	
	SELECT	so.so_id     id,
			0            is_new,
			so.brand_id,
			b.brand_name,
			so.st_id,
			st.st_name,
			so.subject_id,
			sj.subject_name,
			so.season_id,
			s.season_name,
			so.model_year,
			so.sa_local,
			so.sa,
			so.art_name,
			so.model_number,
			so.employee_id,
			so.dt,
			so.ct_id,
			ct.ct_name,
			NULL rv_bigint
	FROM	#t t   
			INNER JOIN	Products.SketchOld so
				ON	so.so_id = t.so_id   
			LEFT JOIN	Products.Brand b
				ON	b.brand_id = so.brand_id   
			LEFT JOIN	Products.SketchType st
				ON	st.st_id = so.st_id   
			LEFT JOIN	Products.[Subject] sj
				ON	sj.subject_id = so.subject_id   
			LEFT JOIN	Products.Season s
				ON	s.season_id = so.season_id   
			LEFT JOIN	Material.ClothType ct
				ON	ct.ct_id = so.ct_id
	UNION ALL
	SELECT	s.sketch_id,
			1 is_new,
			s.brand_id,
			b.brand_name,
			s.st_id,
			st.st_name,
			s.subject_id,
			sj.subject_name,
			s.season_id,
			sn.season_name,
			s.model_year,
			s.sa_local,
			s.sa,
			an.art_name,
			s.model_number,
			s.employee_id,
			s.dt,
			s.ct_id,
			ct.ct_name,
			CAST(s.rv AS BIGINT)
	FROM	#tt t   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = t.sketch_id   
			INNER JOIN	Products.Brand b
				ON	b.brand_id = s.brand_id   
			INNER JOIN	Products.SketchType st
				ON	st.st_id = s.st_id   
			INNER JOIN	Products.[Subject] sj
				ON	sj.subject_id = s.subject_id   
			INNER JOIN	Products.Season sn
				ON	sn.season_id = s.season_id   
			LEFT JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id   
			LEFT JOIN	Material.ClothType ct
				ON	s.ct_id = ct.ct_id   
	
	
	SELECT	sobop.so_id     id,
			0               is_new,
			sobop.office_id
	FROM	#t t   
			INNER JOIN	Products.SketchOldBranchOfficePattern sobop
				ON	sobop.so_id = t.so_id
	UNION ALL
	SELECT	sbop.sketch_id,
			1,
			sbop.office_id
	FROM	#tt t   
			INNER JOIN	Products.SketchBranchOfficePattern sbop
				ON	sbop.sketch_id = t.sketch_id