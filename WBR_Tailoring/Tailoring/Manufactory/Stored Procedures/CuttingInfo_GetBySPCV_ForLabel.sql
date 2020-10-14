CREATE PROCEDURE [Manufactory].[CuttingInfo_GetBySPCV_ForLabel]
	@spcv_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @lining_ao_id INT = 4
	
	SELECT	@error_text = CASE 
	      	                   WHEN spcv.spcv_id IS NULL THEN 'Цветоварианта с кодом ' + CAST(v.spcv_id AS VARCHAR(10)) +
	      	                        ' не существует.'
	      					   WHEN spcv.spcv_id IS NOT NULL AND pan.pan_id IS NULL THEN 'Конфекционная карта не связана с цветовариантом'
	      	                   WHEN pan.pan_id IS NOT NULL AND oa_cp.cnt > 0 AND oa_cp.percnt = 0 THEN 'В составе не указан процент'
	      	                   WHEN pan.pan_id IS NOT NULL AND oa_cp.percnt != 0 AND oa_cp.sum_percnt != 100 THEN 'Сумма процентов в составе не равна 100'
	      	                   WHEN pan.pan_id IS NOT NULL AND oa_cp.cnt = 0 THEN 'Не указан состав'
	      	                   WHEN pan.pan_id IS NOT NULL AND oa_lin_cons.lin_cons_cnt > 0 AND oa_lin_cons.sum_percent != 100 THEN 'Сумма процентов состава подкладки не равна 100'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@spcv_id))v(spcv_id)   
			LEFT JOIN	Planing.SketchPlanColorVariant spcv   
				ON	spcv.spcv_id = v.spcv_id  
			LEFT JOIN Products.ProdArticleNomenclature pan
				ON pan.pan_id = spcv.pan_id
			LEFT JOIN Products.ProdArticle pa 
				ON pa.pa_id = pan.pa_id
			OUTER APPLY (
			      	SELECT	MIN(ISNULL(pac.percnt, 0))  percnt, COUNT(1) cnt, SUM(pac.percnt) sum_percnt
			      	FROM Products.ProdArticleConsist pac
			      	WHERE pac.pa_id = pa.pa_id
			      )  oa_cp
			OUTER APPLY (
	      			SELECT	COUNT(paao.ao_id) lin_cons_cnt, SUM(paao.ao_value) sum_percent
	      			FROM	Products.ProdArticleAddedOption paao   
	      					INNER JOIN	Products.AddedOption ao
	      						ON	ao.ao_id = paao.ao_id
	      			WHERE	ao.ao_id_parent = @lining_ao_id
	      					AND	paao.pa_id = pa.pa_id
				  ) oa_lin_cons 
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	
	DECLARE @covering_id INT
	
	SELECT	@covering_id = cd.covering_id
	FROM	Planing.CoveringDetail cd
	WHERE	cd.spcv_id = @spcv_id
			AND	cd.is_deleted = 0
	
	SELECT	ISNULL(s.imt_name, sj.subject_name_sf) subject_name,
			pa.sa + pan.sa     sa,
			b.brand_name,
			an.art_name,
			col.color_name,
			ts.ts_name,
			c.plan_count,
			ISNULL(oa_ac.actual_count, 0) actual_count,
			oa_cons.cons_cnt,
			oa_lin_cons.lin_cons_cnt,
			oa_carething.carething_cnt,
			spcv.spcv_id,
			s.sketch_id,
			c.cutting_id,
			c.pants_id,
			pan.nm_id,
			cov.office_id,
			os.organization_name,
			os.label_address
	FROM	Manufactory.Cutting c   
			INNER JOIN	Planing.SketchPlanColorVariantTS spcvt
				ON	spcvt.spcvts_id = c.spcvts_id   
			INNER JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.spcv_id = spcvt.spcv_id   
			INNER JOIN	Planing.CoveringDetail cd
				ON	cd.spcv_id = spcv.spcv_id   
			INNER JOIN Planing.Covering cov
				ON cov.covering_id = cd.covering_id			
			INNER JOIN	Products.ProdArticleNomenclatureTechSize pants
				ON	pants.pants_id = c.pants_id   
			INNER JOIN	Products.ProdArticleNomenclature pan
				ON	pan.pan_id = pants.pan_id   
			INNER JOIN	Products.ProdArticle pa
				ON	pa.pa_id = pan.pa_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = pa.sketch_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id   
			INNER JOIN	Products.[Subject] sj
				ON	sj.subject_id = s.subject_id   
			INNER JOIN	Products.Brand b
				ON	b.brand_id = pa.brand_id   
			LEFT JOIN	Products.ProdArticleNomenclatureColor panc   
			INNER JOIN	Products.Color col
				ON	col.color_cod = panc.color_cod
				ON	panc.pan_id = pan.pan_id
				AND	panc.is_main = 1   
			INNER JOIN	Products.TechSize ts
				ON	ts.ts_id = pants.ts_id 
			LEFT JOIN Settings.OfficeSetting os
				ON os.office_id = spcv.sew_office_id  
			OUTER APPLY (
			      	SELECT	SUM(ca.actual_count) actual_count
			      	FROM	Manufactory.CuttingActual ca
			      	WHERE	ca.cutting_id = c.cutting_id
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
	WHERE	cd.covering_id = @covering_id
			AND	cd.is_deleted = 0
			AND spcv.is_deleted = 0
	ORDER BY
		spcv.spcv_id,
		ts.visible_queue,
		ts.ts_name
	
