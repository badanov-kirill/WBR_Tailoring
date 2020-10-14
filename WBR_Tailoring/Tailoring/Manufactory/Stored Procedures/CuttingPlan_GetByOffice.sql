CREATE PROCEDURE [Manufactory].[CuttingPlan_GetByOffice]
	@office_id INT
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
			pa.sa + pan.sa            article,
			ts.ts_name,
			ISNULL(pan.cutting_degree_difficulty, 1) cutting_degree_difficulty,
			s.pt_id,
			pt.pt_name,
			cmp.plan_year,
			cmp.plan_month,
			CAST(cmp.planing_dt AS DATETIME) planing_dt,
			CASE 
			     WHEN cmp.planing_dt IS NULL THEN 0
			     ELSE 1
			END                       is_planing,
			oa_empl.employee_xml,
			pan.pan_id,
			an.art_name
	FROM	Manufactory.Cutting cmp   
			INNER JOIN	Products.ProdArticleNomenclatureTechSize pants
				ON	pants.pants_id = cmp.pants_id   
			INNER JOIN	Products.TechSize ts
				ON	ts.ts_id = pants.ts_id   
			INNER JOIN	Products.ProdArticleNomenclature pan
				ON	pan.pan_id = pants.pan_id   
			INNER JOIN	Products.ProdArticle pa
				ON	pa.pa_id = pan.pa_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = pa.sketch_id   
			INNER JOIN	Products.Brand b
				ON	b.brand_id = pa.brand_id   
			INNER JOIN	Products.[Subject] sj
				ON	sj.subject_id = s.subject_id   
			INNER JOIN	Products.ProductType pt
				ON	pt.pt_id = s.pt_id   
			INNER JOIN Products.ArtName an
				ON an.art_name_id = s.art_name_id
			OUTER APPLY (
			      	SELECT	ce.employee_id '@id'
			      	FROM	Manufactory.CuttingEmployee ce
			      	WHERE	ce.cutting_id = cmp.cutting_id
			      	FOR XML	PATH('empl'), ROOT('employes')
			      ) oa_empl(employee_xml)
	WHERE	cmp.office_id = @office_id
			AND	cmp.plan_count > 0
			AND	cmp.closing_dt IS     NULL
	ORDER BY
		pa.sa + pan.sa,
		ts.ts_name