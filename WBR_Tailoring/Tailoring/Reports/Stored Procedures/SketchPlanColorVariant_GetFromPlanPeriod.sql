CREATE PROCEDURE [Reports].[SketchPlanColorVariant_GetFromPlanPeriod]
	@plan_year SMALLINT,
	@plan_month TINYINT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	ISNULL(v.office_name, ossp.office_name) sew_office_name,
			ISNULL(v.sew_office_id, sp.sew_office_id) sew_office_id,
			s.ct_id,
			ct.ct_name,
			sp.sketch_id,
			an.art_name,
			s.sa,
			ISNULL(v.qty, 0) qty,
			v.corrected_qty,
			sp.sp_id,
			oa_p.x office_pattern
	FROM	Planing.SketchPlan sp   
			LEFT JOIN Settings.OfficeSetting ossp
				ON ossp.office_id = sp.sew_office_id
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = sp.sketch_id   
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
			LEFT JOIN	(SELECT	spcv.sp_id,
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
	WHERE	sp.plan_year = @plan_year
			AND	sp.plan_month = @plan_month
	ORDER BY
		ISNULL(v.sew_office_id, sp.sew_office_id),
		s.ct_id,
		an.art_name

