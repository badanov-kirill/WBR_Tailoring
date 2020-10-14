CREATE PROCEDURE [Planing].[SketchPlan_CheckByBudgetPeriod]
	@plan_year SMALLINT,
	@plan_month TINYINT,
	@sketch_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	psg.psg_name,
			CAST(sp.create_dt AS DATETIME) create_dt,
			v.qty
	FROM	Planing.SketchPlan sp   
			INNER JOIN	Planing.PlanStatus ps
				ON	ps.ps_id = sp.ps_id   
			INNER JOIN	Planing.PlanStatusGroup psg
				ON	psg.psg_id = ps.psg_id   
			LEFT JOIN	(SELECT	spcv.sp_id,
			    	    	 		SUM(spcv.qty) qty
			    	    	 FROM	Planing.SketchPlanColorVariant spcv
			    	    	 WHERE	spcv.is_deleted = 0
			    	    	 GROUP BY
			    	    	 	spcv.sp_id)v
				ON	v.sp_id = sp.sp_id
	WHERE	sp.sketch_id = @sketch_id
			AND	sp.plan_year = @plan_year
			AND	sp.plan_month = @plan_month
