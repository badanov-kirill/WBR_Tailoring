CREATE PROCEDURE [Manufactory].[CuttingPlan_GetForPrint]
	@office_id INT = NULL,
	@plan_year SMALLINT,
	@plan_month TINYINT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	DECLARE @lining_ao_id INT = 4
	
	SELECT	cmp.cutting_id,
			cmp.pants_id,
			cmp.plan_count,
			ISNULL(s.imt_name, sj.subject_name_sf) imt_name,
			b.brand_name,
			pan.nm_id,
			pa.sa + pan.sa     article,
			ts.ts_name,
			ISNULL(oa_ac.actual_count, 0) actual_count,
			oa_cons.cons_cnt,
			oa_lin_cons.lin_cons_cnt,
			oa_carething.carething_cnt
	FROM	Manufactory.Cutting cmp   
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
			      ) oa_ac
			OUTER APPLY (
	      			SELECT	COUNT(pac.consist_id) cons_cnt
	      			FROM	Products.ProdArticleConsist pac
	      			WHERE	pac.pa_id = pa.pa_id
				  ) oa_cons
			OUTER APPLY (
	      			SELECT	COUNT(paao.ao_id) lin_cons_cnt
	      			FROM	Products.ProdArticleAddedOption paao   
	      					INNER JOIN	Products.AddedOption ao
	      						ON	ao.ao_id = paao.ao_id
	      			WHERE	ao.ao_id_parent = @lining_ao_id
	      					AND	paao.pa_id = pa.pa_id
				  ) oa_lin_cons 
			OUTER APPLY (
	      			SELECT	COUNT(paao.ao_id) carething_cnt
	      			FROM	Products.ProdArticleAddedOption paao   
	      					INNER JOIN	Products.CareThingAddedOption ctao
	      						ON	ctao.ao_id = paao.ao_id
	      			WHERE	paao.pa_id = pa.pa_id
				  )                    oa_carething
	WHERE	(@office_id IS NULL OR cmp.office_id = @office_id)
			AND	cmp.plan_year = @plan_year
			AND	cmp.plan_month = @plan_month 
	