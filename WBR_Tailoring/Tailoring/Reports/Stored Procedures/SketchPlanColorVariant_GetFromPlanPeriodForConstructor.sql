CREATE PROCEDURE [Reports].[SketchPlanColorVariant_GetFromPlanPeriodForConstructor]
	@plan_year SMALLINT,
	@plan_month TINYINT,
	@constructor_employee_id INT = NULL,
	@is_covering BIT = NULL,
	@is_buyer BIT = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	v.office_name sew_office_name,
			v.sew_office_id,
			s.ct_id,
			ct.ct_name,
			sp.sketch_id,
			an.art_name,
			s.sa,
			v.qty,
			v.corrected_qty,
			sp.sp_id,
			oa_p.x office_pattern,
			s.constructor_employee_id,
			b.brand_name,
			ISNULL(oa_c.is_covering, 0) is_covering
	FROM	Planing.SketchPlan sp   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = sp.sketch_id 
			INNER JOIN Products.Brand b
				ON b.brand_id = s.brand_id  
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id   
			LEFT JOIN	Material.ClothType ct
				ON	ct.ct_id = s.ct_id  
			OUTER APPLY (
			      	SELECT	os.office_name + '; '
			      	FROM	Products.SketchBranchOfficePattern sbop   
			      			INNER JOIN	Settings.OfficeSetting os
			      				ON	os.office_id = sbop.office_id
			      	WHERE	sbop.sketch_id = s.sketch_id
			      	FOR XML	PATH('')
			      ) oa_p(x) 
			INNER JOIN	(SELECT	spcv.sp_id,
			    	     	 		spcv.sew_office_id,
			    	     	 		os.office_name,
			    	     	 		SUM(spcv.qty) qty,
			    	     	 		SUM(ISNULL(spcv.corrected_qty, spcv.qty)) corrected_qty
			    	     	 FROM	Planing.SketchPlanColorVariant spcv   
			    	     	 		LEFT JOIN	Settings.OfficeSetting os
			    	     	 			ON	os.office_id = spcv.sew_office_id
			    	     	 WHERE	spcv.is_deleted = 0
			    	     	 GROUP BY
			    	     	 	spcv.sp_id,
			    	     	 	spcv.sew_office_id,
			    	     	 	os.office_name)v
				ON	v.sp_id = sp.sp_id
			OUTER APPLY (
			      	SELECT	TOP(1) 1 is_covering
			      	FROM	Planing.CoveringDetail cd   
			      			INNER JOIN	Planing.SketchPlanColorVariant spcv
			      				ON	spcv.spcv_id = cd.spcv_id
			      	WHERE	spcv.sp_id = sp.sp_id
			      ) oa_c
	WHERE	sp.plan_year = @plan_year
			AND	sp.plan_month = @plan_month
			AND (@constructor_employee_id IS NULL OR s.constructor_employee_id = @constructor_employee_id)
			AND (@is_covering IS NULL OR ISNULL(oa_c.is_covering, 0) = @is_covering)
			AND (@is_buyer IS NULL OR (@is_buyer = 1 AND sp.ps_id IN (5, 7)) OR (@is_buyer = 0 AND sp.ps_id NOT IN (5, 7)))
	ORDER BY
		v.sew_office_id,
		s.ct_id,
		an.art_name

