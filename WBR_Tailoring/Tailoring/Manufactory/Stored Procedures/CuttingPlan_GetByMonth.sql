CREATE PROCEDURE [Manufactory].[CuttingPlan_GetByMonth]
	@office_id INT = NULL,
	@plan_year SMALLINT,
	@plan_month TINYINT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	
	SELECT	cmp.office_id,
			os.office_name,
			cmp.cutting_id,
			pants.pants_id,
			cmp.plan_count,
			ISNULL(cmp.perimeter, 0)     perimeter,
			sj.subject_name_sf           imt_name,
			b.brand_name,
			pan.pan_id                    NM_id,
			pa.sa + pan.sa               article,
			ts.ts_name,
			ISNULL(pan.cutting_degree_difficulty, 1) cutting_degree_difficulty,
			CAST(cmp.planing_dt AS DATETIME) planing_dt,
			CASE 
			     WHEN cmp.planing_dt IS NULL THEN 0
			     ELSE cmp.plan_count
			END                          day_plan_count,
			ISNULL(oa_ac.actual_count, 0) actual_count,
			pt.pt_name,
			s.pt_id,
			CAST(cmp.closing_dt AS DATETIME) closing_dt,
			cmp.closing_employee_id,
			an.art_name,
			CAST(cmp.plan_start_dt AS DATETIME) plan_start_dt
	FROM	Manufactory.Cutting cmp   
			INNER JOIN	Settings.OfficeSetting os
				ON	os.office_id = cmp.office_id   
			INNER JOIN	Products.ProdArticleNomenclatureTechSize pants
				ON	cmp.pants_id = pants.pants_id   
			INNER JOIN	Products.ProdArticleNomenclature pan
				ON	pan.pan_id = pants.pan_id   
			INNER JOIN	Products.ProdArticle pa
				ON	pa.pa_id = pan.pa_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = pa.sketch_id
			INNER JOIN Products.ArtName an
				ON an.art_name_id = s.art_name_id   
			INNER JOIN	Products.[Subject] sj
				ON	sj.subject_id = s.subject_id   
			INNER JOIN	Products.Brand b
				ON	b.brand_id = s.brand_id   
			INNER JOIN	Products.TechSize ts
				ON	ts.ts_id = pants.ts_id   
			LEFT JOIN	Products.ProductType pt
				ON pt.pt_id = s.pt_id   
			OUTER APPLY (
			      	SELECT	SUM(ca.actual_count) actual_count
			      	FROM	Manufactory.CuttingActual ca
			      	WHERE	ca.cutting_id = cmp.cutting_id
			      )                      oa_ac
	WHERE	(@office_id IS NULL OR cmp.office_id = @office_id)
			AND	cmp.plan_year = @plan_year
			AND	cmp.plan_month = @plan_month 