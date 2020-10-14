CREATE PROCEDURE [Budget].[PreBudgetSketch_Get_v2]
	@sketch_id INT = NULL,
	@plan_month TINYINT = NULL,
	@plan_year SMALLINT = NULL,
	@planing_employee_id INT = NULL,
	@office_id INT = NULL,
	@ct_id INT = NULL
AS
	SET NOCOUNT ON 
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	pbs.pbs_id,
			pbs.sketch_id,
			pbs.plan_qty,
			pbs.plan_year,
			pbs.plan_month,
			pbs.planing_employee_id,
			pbs.planing_dt,
			pbs.employee_id,
			pbs.dt,
			pbs.office_id,
			an.art_name,
			s.sa_local,
			s.ct_id,
			ct.ct_name,
			ISNULL(s.pattern_name, s.sa_local) pattern_name,
			s.constructor_employee_id,
			s.sa
	FROM	Budget.PreBudgetSketch pbs   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = pbs.sketch_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id   
			LEFT JOIN	Material.ClothType ct
				ON	ct.ct_id = s.ct_id
	WHERE	(@sketch_id IS NULL OR pbs.sketch_id = @sketch_id)
			AND	(@plan_month IS NULL OR pbs.plan_month = @plan_month)
			AND	(@plan_year IS NULL OR pbs.plan_year = @plan_year)
			AND	(@planing_employee_id IS NULL OR pbs.planing_employee_id = @planing_employee_id)
			AND	(@office_id IS NULL OR pbs.office_id = @office_id)
			AND	(@ct_id IS NULL OR s.ct_id = @ct_id)
	ORDER BY
		pbs.plan_year,
		pbs.plan_month,
		pbs.planing_employee_id,
		pbs.planing_dt