CREATE PROCEDURE [Manufactory].[CuttingPlan_GetByEmployee]
	@employee_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	
	SELECT	cmp.cutting_id,
			cmp.pants_id,
			cmp.plan_count,
			cmp.perimeter,
			ISNULL(s.imt_name, sj.subject_name_sf) imt_name,
			b.brand_name,
			pan.nm_id,
			pa.sa + pan.sa     article,
			ts.ts_name,
			oa_aa.actual_count,
			ISNULL(pan.cutting_degree_difficulty, 1) cutting_degree_difficulty,
			CAST(cmp.planing_dt AS DATETIME) planing_dt
	FROM	Manufactory.Cutting cmp   
			INNER JOIN	Manufactory.CuttingEmployee ce
				ON	ce.cutting_id = cmp.cutting_id   
			INNER JOIN	Products.ProdArticleNomenclatureTechSize pants
				ON	pants.pants_id = cmp.pants_id   
			INNER JOIN	Products.ProdArticleNomenclature pan
				ON	pan.pan_id = pants.pan_id   
			INNER JOIN	Products.ProdArticle pa
				ON	pa.pa_id = pan.pa_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = pa.sketch_id   
			INNER JOIN	Products.[Subject] sj
				ON	sj.subject_id = s.subject_id   
			INNER JOIN	Products.Brand b
				ON	b.brand_id = pa.brand_id   
			INNER JOIN	Products.TechSize ts
				ON	ts.ts_id = pants.ts_id   
			OUTER APPLY (
			      	SELECT	SUM(ca.actual_count) actual_count
			      	FROM	Manufactory.CuttingActual ca
			      	WHERE	ca.cutting_id = cmp.cutting_id
			      )            oa_aa
	WHERE	ce.employee_id = @employee_id
			AND	cmp.planing_dt IS NOT NULL
			AND	cmp.plan_count > 0
			AND	cmp.closing_dt IS NULL
	ORDER BY
		pa.sa + pan.sa,
		ts.ts_name