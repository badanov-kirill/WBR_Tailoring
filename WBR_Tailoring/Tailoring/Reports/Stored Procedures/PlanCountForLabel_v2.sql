CREATE PROCEDURE [Reports].[PlanCountForLabel_v2]
	@start_dt DATE = NULL,
	@finish_dt DATE = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	DECLARE @dt DATE = GETDATE()
	IF @start_dt IS NULL
	SET @start_dt = DATEFROMPARTS(YEAR(@dt), MONTH(@dt), 1)
	
	IF @finish_dt IS NULL
	SET @finish_dt = DATEADD(MONTH, 6, @start_dt)
	
	SELECT	CAST(c.calendar_date AS DATETIME) dt,
			rmt.rmt_name,
			v_wh.qty qty_warehouse,
			v_lb.qty_for_one * ISNULL(v_plant.plant_qty, 0) plant_qty,
			v_lb.qty_for_one,
			v_lb.qty_for_one * ISNULL(v_plan.plan_qty, 0) plan_qty,
			v_lb.qty_for_one * ISNULL(v_plan.ordered_qty, 0) ordered_qty
	FROM	Material.RawMaterialType rmt   
			CROSS JOIN	RefBook.Calendar c   
			LEFT JOIN	(SELECT	smai.rmt_id,
			    	    	 		CAST(SUM(smai.stor_unit_residues_qty) AS INT) qty
			    	    	 FROM	Warehouse.SHKRawMaterialActualInfo smai   
			    	    	 		INNER JOIN	Warehouse.SHKRawMaterialState sms
			    	    	 			ON	sms.shkrm_id = smai.shkrm_id
			    	    	 WHERE	sms.state_id = 3
			    	    	 GROUP BY
			    	    	 	smai.rmt_id)v_wh
				ON	v_wh.rmt_id = rmt.rmt_id   
			LEFT JOIN	(SELECT	lb.rmt_id,
			    	    	 		MAX(lb.qty) qty_for_one
			    	    	 FROM	Settings.LabelBrand lb
			    	    	 GROUP BY
			    	    	 	lb.rmt_id)v_lb
				ON	v_lb.rmt_id = rmt.rmt_id   
			LEFT JOIN	(SELECT	lb.rmt_id,
			    	    	 		MONTH(DATEADD(DAY, -60, sp.plan_sew_dt)) m,
			    	    	 		YEAR(DATEADD(DAY, -60, sp.plan_sew_dt)) y,
			    	    	 		SUM(CASE WHEN sp.ps_id IN (2, 6) THEN spcv.qty ELSE 0 END) plan_qty,
			    	    	 		SUM(CASE WHEN sp.ps_id IN (5, 7) THEN spcv.qty ELSE 0 END) ordered_qty
			    	    	 FROM	Planing.SketchPlanColorVariant spcv   
			    	    	 		INNER JOIN	Planing.SketchPlan sp
			    	    	 			ON	sp.sp_id = spcv.sp_id   
			    	    	 		INNER JOIN	Products.Sketch s
			    	    	 			ON	s.sketch_id = sp.sketch_id   
			    	    	 		INNER JOIN	Settings.LabelBrand lb
			    	    	 			ON	lb.brand_id = s.brand_id
			    	    	 WHERE	spcv.is_deleted = 0
			    	    	 		AND	sp.plan_sew_dt >= DATEADD(DAY, 60, @start_dt)
			    	    	 		AND	sp.plan_sew_dt <= DATEADD(DAY, 60, @finish_dt)
			    	    	 		AND	sp.ps_id IN (2, 5, 6, 7)
			    	    	 GROUP BY
			    	    	 	lb.rmt_id,
			    	    	 	MONTH(DATEADD(DAY, -60, sp.plan_sew_dt)),
			    	    	 	YEAR(DATEADD(DAY, -60, sp.plan_sew_dt)))v_plan
				ON	v_plan.rmt_id = rmt.rmt_id
				AND	v_plan.m = MONTH(c.calendar_date)
				AND	v_plan.y = YEAR(c.calendar_date)   
			LEFT JOIN	(SELECT	lb.rmt_id,
			    	    	 		SUM(spcv.qty) plant_qty
			    	    	 FROM	Planing.SketchPlanColorVariant spcv   
			    	    	 		INNER JOIN	Planing.SketchPlan sp
			    	    	 			ON	sp.sp_id = spcv.sp_id   
			    	    	 		INNER JOIN	Products.Sketch s
			    	    	 			ON	s.sketch_id = sp.sketch_id   
			    	    	 		INNER JOIN	Settings.LabelBrand lb
			    	    	 			ON	lb.brand_id = s.brand_id
			    	    	 WHERE	spcv.is_deleted = 0
			    	    			AND spcv.dt >= DATEADD(MONTH, -6, @dt)
			    	    	 		AND	sp.ps_id IN (4, 8, 10)
			    	    	 		AND	spcv.cvs_id NOT IN (1, 15)
			    	    	 GROUP BY
			    	    	 	lb.rmt_id)v_plant
				ON	v_plant.rmt_id = rmt.rmt_id
	WHERE	EXISTS (
	     		SELECT	1
	     		FROM	Settings.LabelBrand lb
	     		WHERE	lb.rmt_id = rmt.rmt_id
	     	)
			AND	c.calendar_date >= @start_dt
			AND	c.calendar_date <= @finish_dt
			AND	DAY(c.calendar_date) = 1
	UNION
	ALL
	SELECT	CAST(c.calendar_date AS DATETIME) dt,
			rmtl.rmt_name                    rmt_name,
			ISNULL(v_wl.qty, 0)              qty_warehouse,
			ISNULL(v_plant.plant_qty, 0)     plant_qty,
			1                                qty_for_one,
			ISNULL(v_plan.plan_qty, 0)       plan_qty,
			ISNULL(v_plan.ordered_qty, 0) ordered_qty
	FROM	Products.Brand b   
			CROSS JOIN	RefBook.Calendar c   
			INNER JOIN	Settings.LabelBrandTS lbt
				ON	lbt.brand_id = b.brand_id   
			INNER JOIN	Products.TechSize ts
				ON	ts.ts_id = lbt.ts_id   
			INNER JOIN	Material.RawMaterialType rmtl
				ON	rmtl.rmt_id = lbt.rmt_id   
			LEFT JOIN	(SELECT	MONTH(DATEADD(DAY, -60, sp.plan_sew_dt)) m,
			    	    	 		YEAR(DATEADD(DAY, -60, sp.plan_sew_dt)) y,
			    	    	 		s.brand_id,
			    	    	 		sts2.ts_id,
			    	    	 		SUM(
			    	    	 			CASE 
			    	    	 			     WHEN sp.ps_id IN (2, 6) THEN spcv.qty *
			    	    	 			          ISNULL(bvtd.cnt, 1) /
			    	    	 			          CASE 
			    	    	 			               WHEN ISNULL(oa_bvtd.sum_ts_cnt, 0) > 0 THEN oa_bvtd.sum_ts_cnt
			    	    	 			               WHEN ISNULL(oa_ts.cnt_ts, 0) > 0 THEN oa_ts.cnt_ts
			    	    	 			               ELSE 1
			    	    	 			          END
			    	    	 			     ELSE 0
			    	    	 			END
			    	    	 		)     plan_qty,
			    	    	 		SUM(
			    	    	 			CASE 
			    	    	 			     WHEN sp.ps_id IN (5, 7) THEN spcv.qty *
			    	    	 			          ISNULL(bvtd.cnt, 1) /
			    	    	 			          CASE 
			    	    	 			               WHEN ISNULL(oa_bvtd.sum_ts_cnt, 0) > 0 THEN oa_bvtd.sum_ts_cnt
			    	    	 			               WHEN ISNULL(oa_ts.cnt_ts, 0) > 0 THEN oa_ts.cnt_ts
			    	    	 			               ELSE 1
			    	    	 			          END
			    	    	 			     ELSE 0
			    	    	 			END
			    	    	 		)     ordered_qty
			    	    	 FROM	Planing.SketchPlanColorVariant spcv   
			    	    	 		INNER JOIN	Planing.SketchPlan sp
			    	    	 			ON	sp.sp_id = spcv.sp_id   
			    	    	 		INNER JOIN	Products.Sketch s
			    	    	 			ON	s.sketch_id = sp.sketch_id   
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
			    	    	 			ON	sts2.sketch_id = s.sketch_id   
			    	    	 		LEFT JOIN	Settings.BrandVarianTSDetail bvtd
			    	    	 			ON	bvtd.ts_id = sts2.ts_id
			    	    	 			AND	bvtd.bvts_id = bvt.bvts_id
			    	    	 WHERE	spcv.is_deleted = 0
			    	    	 		AND	sp.plan_sew_dt >= DATEADD(DAY, 60, @start_dt)
			    	    	 		AND	sp.plan_sew_dt <= DATEADD(DAY, 60, @finish_dt)
			    	    	 		AND	sp.ps_id IN (2, 5, 6, 7)
			    	    	 GROUP BY
			    	    	 	MONTH(DATEADD(DAY, -60, sp.plan_sew_dt)),
			    	    	 	YEAR(DATEADD(DAY, -60, sp.plan_sew_dt)),
			    	    	 	s.brand_id,
			    	    	 	sts2.ts_id)v_plan
				ON	v_plan.brand_id = b.brand_id
				AND	v_plan.ts_id = ts.ts_id
				AND	v_plan.m = MONTH(c.calendar_date)
				AND	v_plan.y = YEAR(c.calendar_date)   
			LEFT JOIN	(SELECT	s.brand_id,
			    	    	 		sts2.ts_id,
			    	    	 		SUM(
			    	    	 			spcv.qty *
			    	    	 			ISNULL(bvtd.cnt, 1) /
			    	    	 			CASE 
			    	    	 			     WHEN ISNULL(oa_bvtd.sum_ts_cnt, 0) > 0 THEN oa_bvtd.sum_ts_cnt
			    	    	 			     WHEN ISNULL(oa_ts.cnt_ts, 0) > 0 THEN oa_ts.cnt_ts
			    	    	 			     ELSE 1
			    	    	 			END
			    	    	 		) plant_qty
			    	    	 FROM	Planing.SketchPlanColorVariant spcv   
			    	    	 		INNER JOIN	Planing.SketchPlan sp
			    	    	 			ON	sp.sp_id = spcv.sp_id   
			    	    	 		INNER JOIN	Products.Sketch s
			    	    	 			ON	s.sketch_id = sp.sketch_id   
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
			    	    	 			ON	sts2.sketch_id = s.sketch_id   
			    	    	 		LEFT JOIN	Settings.BrandVarianTSDetail bvtd
			    	    	 			ON	bvtd.ts_id = sts2.ts_id
			    	    	 			AND	bvtd.bvts_id = bvt.bvts_id
			    	    	 WHERE	spcv.is_deleted = 0
			    	    			AND spcv.dt >= DATEADD(MONTH, -6, @dt)
			    	    	 		AND	sp.ps_id IN (4, 8, 10)
			    	    	 		AND	spcv.cvs_id NOT IN (1, 15)
			    	    	 GROUP BY
			    	    	 	s.brand_id,
			    	    	 	sts2.ts_id)v_plant
				ON	v_plant.brand_id = b.brand_id
				AND	v_plant.ts_id = ts.ts_id   
			LEFT JOIN	(SELECT	smai.rmt_id,
			    	    	 		CAST(SUM(smai.stor_unit_residues_qty) AS INT) qty
			    	    	 FROM	Warehouse.SHKRawMaterialActualInfo smai   
			    	    	 		INNER JOIN	Warehouse.SHKRawMaterialState sms
			    	    	 			ON	sms.shkrm_id = smai.shkrm_id
			    	    	 WHERE	sms.state_id = 3
			    	    	 GROUP BY
			    	    	 	smai.rmt_id)v_wl
				ON	v_wl.rmt_id = lbt.rmt_id
	WHERE	c.calendar_date >= @start_dt
			AND	c.calendar_date <= @finish_dt
			AND	DAY(c.calendar_date) = 1

