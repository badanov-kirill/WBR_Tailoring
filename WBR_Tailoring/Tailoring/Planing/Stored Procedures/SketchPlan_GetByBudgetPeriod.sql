CREATE PROCEDURE [Planing].[SketchPlan_GetByBudgetPeriod]
	@employee_id INT = NULL,
	@plan_year SMALLINT,
	@plan_month TINYINT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	ct.ct_name,
			b.brand_name,
			sj.subject_name,
			an.art_name,
			s.sa,
			psg.psg_name,
			ps.ps_name,
			v.qty,
			os.office_name
	FROM	Planing.SketchPlan sp   
			INNER JOIN	Planing.PlanStatus ps
				ON	ps.ps_id = sp.ps_id   
			INNER JOIN	Planing.PlanStatusGroup psg
				ON	psg.psg_id = ps.psg_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = sp.sketch_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id   
			INNER JOIN	Products.[Subject] sj
				ON	sj.subject_id = s.subject_id   
			INNER JOIN	Products.Brand b
				ON	b.brand_id = s.brand_id   
			LEFT JOIN	Material.ClothType ct
				ON	ct.ct_id = s.ct_id   
			LEFT JOIN Settings.OfficeSetting os
				ON os.office_id = sp.sew_office_id
			LEFT JOIN	(SELECT	spcv.sp_id,
			    	    	 		SUM(spcv.qty) qty
			    	    	 FROM	Planing.SketchPlanColorVariant spcv
			    	    	 WHERE	spcv.is_deleted = 0
			    	    	 GROUP BY
			    	    	 	spcv.sp_id)v
				ON	v.sp_id = sp.sp_id
	WHERE	(@employee_id IS NULL OR sp.create_employee_id = @employee_id)
			AND	sp.plan_year = @plan_year
			AND	sp.plan_month = @plan_month
			AND	psg.psg_id IN (1, 2, 5, 8)