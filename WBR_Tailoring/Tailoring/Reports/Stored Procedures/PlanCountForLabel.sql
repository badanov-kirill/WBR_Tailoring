CREATE PROCEDURE [Reports].[PlanCountForLabel]
	@start_dt DATE,
	@finish_dt DATE
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	b.brand_name,
			ts.ts_name,
			'План'     plan_type,
			SUM(
				spcv.qty * 
				ISNULL(bvtd.cnt, 1) / 
				CASE 
				     WHEN ISNULL(oa_bvtd.sum_ts_cnt, 0) > 0 THEN oa_bvtd.sum_ts_cnt
				     WHEN ISNULL(oa_ts.cnt_ts, 0) > 0 THEN oa_ts.cnt_ts
				     ELSE 1
				END
			)           qty
	FROM	Planing.SketchPlanColorVariant spcv   
			INNER JOIN	Planing.SketchPlan sp
				ON	sp.sp_id = spcv.sp_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = sp.sketch_id   
			INNER JOIN	Products.Brand b
				ON	b.brand_id = s.brand_id   
			OUTER APPLY (
			      	SELECT	MAX(ts.ts_name) max_ts_name,
			      			MIN(ts.ts_name) min_ts_name,
			      			COUNT(ts.ts_id) cnt_ts
			      	FROM	Products.SketchTechSize sts   
			      			INNER JOIN	Products.TechSize ts
			      				ON	ts.ts_id = sts.ts_id
			      	WHERE	sts.sketch_id = s.sketch_id
			      ) oa_ts
	LEFT JOIN	Settings.BrandVarianTS bvt
				ON	bvt.brand_id = s.brand_id
				AND	bvt.max_ts_name = oa_ts.max_ts_name
				AND	bvt.min_ts_name = oa_ts.min_ts_name
				AND	bvt.cnt_ts = oa_ts.cnt_ts   
			OUTER APPLY (
			      	SELECT	SUM(bvtd.cnt) sum_ts_cnt
			      	FROM	Settings.BrandVarianTSDetail bvtd
			      	WHERE	bvtd.bvts_id = bvt.bvts_id
			      ) oa_bvtd
	INNER JOIN	Products.SketchTechSize sts2   
			INNER JOIN	Products.TechSize ts
				ON	ts.ts_id = sts2.ts_id
				ON	sts2.sketch_id = s.sketch_id   
			LEFT JOIN	Settings.BrandVarianTSDetail bvtd
				ON	bvtd.ts_id = sts2.ts_id
				AND	bvtd.bvts_id = bvt.bvts_id
	WHERE	sp.ps_id IN (2, 6)
			AND	spcv.is_deleted = 0
			AND	sp.plan_sew_dt >= DATEADD(DAY, 60, @start_dt)
			AND	sp.plan_sew_dt <= DATEADD(DAY, 60, @finish_dt)
	GROUP BY
		b.brand_name,
		ts.ts_name
	UNION 	ALL		
	SELECT	b.brand_name,
			ts.ts_name,
			'Заказ'     plan_type,
			SUM(
				spcv.qty * 
				ISNULL(bvtd.cnt, 1) / 
				CASE 
				     WHEN ISNULL(oa_bvtd.sum_ts_cnt, 0) > 0 THEN oa_bvtd.sum_ts_cnt
				     WHEN ISNULL(oa_ts.cnt_ts, 0) > 0 THEN oa_ts.cnt_ts
				     ELSE 1
				END
			)           qty
	FROM	Planing.SketchPlanColorVariant spcv   
			INNER JOIN	Planing.SketchPlan sp
				ON	sp.sp_id = spcv.sp_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = sp.sketch_id   
			INNER JOIN	Products.Brand b
				ON	b.brand_id = s.brand_id   
			OUTER APPLY (
			      	SELECT	MAX(ts.ts_name) max_ts_name,
			      			MIN(ts.ts_name) min_ts_name,
			      			COUNT(ts.ts_id) cnt_ts
			      	FROM	Products.SketchTechSize sts   
			      			INNER JOIN	Products.TechSize ts
			      				ON	ts.ts_id = sts.ts_id
			      	WHERE	sts.sketch_id = s.sketch_id
			      ) oa_ts
	LEFT JOIN	Settings.BrandVarianTS bvt
				ON	bvt.brand_id = s.brand_id
				AND	bvt.max_ts_name = oa_ts.max_ts_name
				AND	bvt.min_ts_name = oa_ts.min_ts_name
				AND	bvt.cnt_ts = oa_ts.cnt_ts   
			OUTER APPLY (
			      	SELECT	SUM(bvtd.cnt) sum_ts_cnt
			      	FROM	Settings.BrandVarianTSDetail bvtd
			      	WHERE	bvtd.bvts_id = bvt.bvts_id
			      ) oa_bvtd
	INNER JOIN	Products.SketchTechSize sts2   
			INNER JOIN	Products.TechSize ts
				ON	ts.ts_id = sts2.ts_id
				ON	sts2.sketch_id = s.sketch_id   
			LEFT JOIN	Settings.BrandVarianTSDetail bvtd
				ON	bvtd.ts_id = sts2.ts_id
				AND	bvtd.bvts_id = bvt.bvts_id
	WHERE	sp.ps_id IN (5, 7)
			AND	spcv.is_deleted = 0
			AND	sp.plan_sew_dt >= DATEADD(DAY, 60, @start_dt)
			AND	sp.plan_sew_dt <= DATEADD(DAY, 60, @finish_dt)
	GROUP BY
		b.brand_name,
		ts.ts_name
	UNION ALL		
	SELECT	b.brand_name,
			ts.ts_name,
			'В запуске'     plan_type,
			SUM(
				ISNULL(spcv.corrected_qty, spcv.qty) * 
				ISNULL(bvtd.cnt, 1) / 
				CASE 
				     WHEN ISNULL(oa_bvtd.sum_ts_cnt, 0) > 0 THEN oa_bvtd.sum_ts_cnt
				     WHEN ISNULL(oa_ts.cnt_ts, 0) > 0 THEN oa_ts.cnt_ts
				     ELSE 1
				END
			)              qty
	FROM	Planing.SketchPlanColorVariant spcv   
			INNER JOIN	Planing.SketchPlan sp
				ON	sp.sp_id = spcv.sp_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = sp.sketch_id   
			INNER JOIN	Products.Brand b
				ON	b.brand_id = s.brand_id   
			OUTER APPLY (
			      	SELECT	MAX(ts.ts_name) max_ts_name,
			      			MIN(ts.ts_name) min_ts_name,
			      			COUNT(ts.ts_id) cnt_ts
			      	FROM	Products.SketchTechSize sts   
			      			INNER JOIN	Products.TechSize ts
			      				ON	ts.ts_id = sts.ts_id
			      	WHERE	sts.sketch_id = s.sketch_id
			      ) oa_ts
	LEFT JOIN	Settings.BrandVarianTS bvt
				ON	bvt.brand_id = s.brand_id
				AND	bvt.max_ts_name = oa_ts.max_ts_name
				AND	bvt.min_ts_name = oa_ts.min_ts_name
				AND	bvt.cnt_ts = oa_ts.cnt_ts   
			OUTER APPLY (
			      	SELECT	SUM(bvtd.cnt) sum_ts_cnt
			      	FROM	Settings.BrandVarianTSDetail bvtd
			      	WHERE	bvtd.bvts_id = bvt.bvts_id
			      ) oa_bvtd
	INNER JOIN	Products.SketchTechSize sts2   
			INNER JOIN	Products.TechSize ts
				ON	ts.ts_id = sts2.ts_id
				ON	sts2.sketch_id = s.sketch_id   
			LEFT JOIN	Settings.BrandVarianTSDetail bvtd
				ON	bvtd.ts_id = sts2.ts_id
				AND	bvtd.bvts_id = bvt.bvts_id
	WHERE	sp.ps_id IN (4, 8, 10)
			AND	spcv.is_deleted = 0
			AND	sp.plan_sew_dt >= DATEADD(DAY, 60, @start_dt)
			AND	sp.plan_sew_dt <= DATEADD(DAY, 60, @finish_dt)
	GROUP BY
		b.brand_name,
		ts.ts_name
	ORDER BY
		b.brand_name,
		ts.ts_name