CREATE PROCEDURE [Reports].[SketchBranchOfficePattern_Get]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	s.sketch_id,
			b.brand_name,
			an.art_name,
			s.sa,
			sj.subject_name,
			ct.ct_name,
			CAST(s.construction_close_dt AS DATETIME) construction_close_dt,
			es.employee_name     constructor_employee_name,
			os.office_name       pattern_office_name
	FROM	Products.Sketch s   
			INNER JOIN	Products.[Subject] sj
				ON	sj.subject_id = s.subject_id   
			INNER JOIN	Products.Brand b
				ON	b.brand_id = s.brand_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id 
			LEFT JOIN Material.ClothType ct
				ON ct.ct_id = s.ct_id  
			INNER JOIN	Products.SketchBranchOfficePattern sbop
				ON	sbop.sketch_id = s.sketch_id   
			INNER JOIN	Settings.OfficeSetting os
				ON	os.office_id = sbop.office_id   
			LEFT JOIN	Settings.EmployeeSetting es
				ON	s.constructor_employee_id = es.employee_id