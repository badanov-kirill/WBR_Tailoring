CREATE PROCEDURE [Products].[Sketch_GetListByTechnolog]
	@is_deleted BIT = 0,
	@brand_id INT = NULL,
	@art_name VARCHAR(100) = NULL,
	@subject_id INT = NULL,
	@sa VARCHAR(36) = NULL,
	@ct_id INT = NULL,
	@employee_id INT = NULL,
	@is_technology BIT = NULL
AS
	SET NOCOUNT ON 
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	
	SELECT	s.sketch_id,
			s.pic_count,
			s.tech_design,
			s.is_deleted,
			s.subject_id,
			s2.subject_name,
			an.art_name,
			s.brand_id,
			b.brand_name,
			s.sa,
			ct.ct_name,
			s.ct_id,
			oa.begin_employee_id     technolog_employee_id,
			CAST(s.specification_dt AS DATETIME) specification_dt,
			ss.ss_name
	FROM	Products.Sketch s
			INNER JOIN Products.SketchStatus ss
				ON ss.ss_id = s.ss_id   
			INNER JOIN	Products.[Subject] s2
				ON	s2.subject_id = s.subject_id 			
			LEFT JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id   
			LEFT JOIN	Products.Brand b
				ON	b.brand_id = s.brand_id  
			LEFT JOIN Material.ClothType ct
				ON ct.ct_id = s.ct_id   
			OUTER APPLY (
			      	SELECT	TOP(1) stj.begin_employee_id
			      	FROM	Products.SketchTechnologyJob stj
			      	WHERE	stj.sketch_id = s.sketch_id
			      			AND	stj.begin_employee_id IS NOT NULL
			      	ORDER BY
			      		stj.stj_id ASC
			      )                  oa
	WHERE	s.is_deleted = @is_deleted
			AND	(@brand_id IS NULL OR s.brand_id = @brand_id)
			AND	(@art_name IS NULL OR an.art_name LIKE @art_name + '%')
			AND	(@subject_id IS NULL OR s.subject_id = @subject_id)
			AND	(@employee_id IS NULL OR oa.begin_employee_id = @employee_id)
			AND	(@sa IS NULL OR s.sa LIKE @sa + '%')
			AND	(@ct_id IS NULL OR s.ct_id = @ct_id)
			AND (@is_technology IS NULL OR (oa.begin_employee_id IS NOT NULL AND @is_technology = 1) OR (oa.begin_employee_id IS NULL AND @is_technology = 0)) 
	ORDER BY
		s.sketch_id DESC