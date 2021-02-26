CREATE PROCEDURE [Manufactory].[CuttingInfo_GetBySPCV_ForMaster]
	@spcv_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Planing.SketchPlanColorVariant spcv
	   	WHERE	spcv.spcv_id = @spcv_id
	   )
	BEGIN
	    RAISERROR('Цветоварианта с кодом %d не существует', 16, 1, @spcv_id)
	    RETURN
	END
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Products.SketchTechnologyJob stj   
	   			INNER JOIN	Planing.SketchPlan sp
	   				ON	sp.sketch_id = stj.sketch_id   
	   			INNER JOIN	Planing.SketchPlanColorVariant spcv
	   				ON	spcv.sp_id = sp.sp_id
	   	WHERE	spcv.spcv_id = @spcv_id
	   			AND	stj.end_dt IS NOT NULL
	   )
	BEGIN
	    RAISERROR('Не закончена тех последовательность', 16, 1)
	    RETURN
	END
	
	IF EXISTS(SELECT 1 FROM Manufactory.SPCV_ForTechSeq sfts WHERE sfts.spcv_id = @spcv_id AND sfts.finish_dt IS NULL)
	BEGIN
	    RAISERROR('Цветовариант находится на проработке в очереди технолога', 16, 1)
	    RETURN
	END	
	
	SELECT	ISNULL(s.imt_name, sj.subject_name_sf) subject_name,
			pa.sa + pan.sa sa,
			b.brand_name,
			an.art_name,
			col.color_name,
			spcv.spcv_id,
			s.sketch_id,
			pan.nm_id,
			CAST(spcv.deadline_package_dt AS DATETIME) deadline_package_dt
	FROM	Planing.SketchPlanColorVariant spcv   
			INNER JOIN	Products.ProdArticleNomenclature pan
				ON	pan.pan_id = spcv.pan_id   
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
	WHERE	spcv.spcv_id = @spcv_id
			AND	spcv.is_deleted = 0
	
	
	SELECT	ts.ts_name,
			c.plan_count,
			ISNULL(oa_ac.actual_count, 0) actual_count,
			c.cutting_id,
			c.pants_id,
			spcvt.spcvts_id,
			ISNULL(spcvt.cut_cnt_for_job, 0) cut_cnt_for_job,
			ISNULL(oa_contr.sew_count, 0) contract_sew_cnt
	FROM	Manufactory.Cutting c   
			INNER JOIN	Planing.SketchPlanColorVariantTS spcvt
				ON	spcvt.spcvts_id = c.spcvts_id   
			INNER JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.spcv_id = spcvt.spcv_id   
			INNER JOIN	Products.TechSize ts
				ON	ts.ts_id = spcvt.ts_id   
			OUTER APPLY (
			      	SELECT	SUM(ca.actual_count) actual_count
			      	FROM	Manufactory.CuttingActual ca
			      	WHERE	ca.cutting_id = c.cutting_id
			      ) oa_ac
			OUTER APPLY (
			      	SELECT	SUM(csc.cnt) sew_count
			      	FROM	Manufactory.ContractorSewCount csc
			      	WHERE	csc.spcvts_id = spcvt.spcvts_id
			      ) oa_contr
	WHERE	spcv.spcv_id = @spcv_id
			AND	spcv.is_deleted = 0
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Manufactory.SPCV_ForTechSeq sfts
	   	WHERE	sfts.spcv_id = @spcv_id
	   			AND	sfts.finish_dt IS NOT NULL
	   )
	BEGIN
	    SELECT	ts.operation_range,
	    		ts.ct_id,
	    		ct.ct_name,
	    		ts.ta_id,
	    		ta.ta_name            ta,
	    		ts.element_id,
	    		e.element_name        element,
	    		ts.equipment_id,
	    		eq.equipment_name     equipment,
	    		ts.dr_id,
	    		ts.dc_id,
	    		ts.operation_value,
	    		ts.discharge_id,
	    		ts.rotaiting,
	    		ts.dc_coefficient,
	    		cd.comment,
	    		ts.operation_time,
	    		stsjc.cost_per_hour * ts.operation_time / 3600 operation_cost
	    FROM	Planing.SketchPlanColorVariant spcv   
	    		INNER JOIN	Products.ProdArticleNomenclature pan
	    			ON	pan.pan_id = spcv.pan_id   
	    		INNER JOIN	Products.ProdArticle pa
	    			ON	pa.pa_id = pan.pa_id   
	    		INNER JOIN	Products.Sketch s
	    			ON	s.sketch_id = pa.sketch_id   
	    		INNER JOIN	Products.TechnologicalSequence ts
	    			ON	ts.sketch_id = s.sketch_id   
	    		INNER JOIN	Material.ClothType ct
	    			ON	ct.ct_id = ts.ct_id   
	    		INNER JOIN	Technology.TechAction ta
	    			ON	ta.ta_id = ts.ta_id   
	    		INNER JOIN	Technology.Element e
	    			ON	e.element_id = ts.element_id   
	    		INNER JOIN	Technology.Equipment eq
	    			ON	eq.equipment_id = ts.equipment_id   
	    		INNER JOIN	Technology.CommentDict cd
	    			ON	cd.comment_id = ts.comment_id   
	    		LEFT JOIN	Manufactory.SPCV_TechnologicalSequenceJobCost stsjc
	    			ON	stsjc.discharge_id = ts.discharge_id
	    			AND	spcv.sew_office_id = stsjc.office_id
	    WHERE	spcv.spcv_id = @spcv_id
	    		AND	spcv.is_deleted = 0
	    		AND ts.operation_time != 0
	    ORDER BY
	    	ts.operation_range
	END
	ELSE
	BEGIN
	    SELECT	ts.operation_range,
	    		ts.ct_id,
	    		ct.ct_name,
	    		ts.ta_id,
	    		ta.ta_name            ta,
	    		ts.element_id,
	    		e.element_name        element,
	    		ts.equipment_id,
	    		eq.equipment_name     equipment,
	    		ts.dr_id,
	    		ts.dc_id,
	    		ts.operation_value,
	    		ts.discharge_id,
	    		ts.rotaiting,
	    		ts.dc_coefficient,
	    		cd.comment,
	    		ts.operation_time,
	    		stsjc.cost_per_hour * ts.operation_time / 3600 operation_cost
	    FROM	Planing.SketchPlanColorVariant spcv   
	    		INNER JOIN	Manufactory.SPCV_TechnologicalSequence ts
	    			ON	ts.spcv_id = spcv.spcv_id   
	    		INNER JOIN	Material.ClothType ct
	    			ON	ct.ct_id = ts.ct_id   
	    		INNER JOIN	Technology.TechAction ta
	    			ON	ta.ta_id = ts.ta_id   
	    		INNER JOIN	Technology.Element e
	    			ON	e.element_id = ts.element_id   
	    		INNER JOIN	Technology.Equipment eq
	    			ON	eq.equipment_id = ts.equipment_id   
	    		INNER JOIN	Technology.CommentDict cd
	    			ON	cd.comment_id = ts.comment_id   
	    		LEFT JOIN	Manufactory.SPCV_TechnologicalSequenceJobCost stsjc
	    			ON	stsjc.discharge_id = ts.discharge_id
	    			AND	spcv.sew_office_id = stsjc.office_id
	    WHERE	spcv.spcv_id = @spcv_id
	    		AND	spcv.is_deleted = 0
	    ORDER BY
	    	ts.operation_range
	END
	
	SELECT	ts.operation_range,
			ts.ct_id,
			ct.ct_name,
			ts.ta_id,
			ta.ta_name            ta,
			ts.element_id,
			e.element_name        element,
			ts.equipment_id,
			eq.equipment_name     equipment,
			ts.dr_id,
			ts.dc_id,
			ts.operation_value,
			ts.discharge_id,
			ts.rotaiting,
			ts.dc_coefficient,
			cd.comment,
			ts.operation_time,
			ts.sts_id,
			stsjc.cost_per_hour * ts.operation_time / 3600 operation_cost
	FROM	Manufactory.SPCV_TechnologicalSequence ts   
			INNER JOIN	Material.ClothType ct
				ON	ct.ct_id = ts.ct_id   
			INNER JOIN	Technology.TechAction ta
				ON	ta.ta_id = ts.ta_id   
			INNER JOIN	Technology.Element e
				ON	e.element_id = ts.element_id   
			INNER JOIN	Technology.Equipment eq
				ON	eq.equipment_id = ts.equipment_id   
			INNER JOIN	Technology.CommentDict cd
				ON	cd.comment_id = ts.comment_id   
			INNER JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.spcv_id = ts.spcv_id   
			LEFT JOIN	Manufactory.SPCV_TechnologicalSequenceJobCost stsjc
				ON	stsjc.discharge_id = ts.discharge_id
				AND	spcv.sew_office_id = stsjc.office_id
	WHERE	ts.spcv_id = @spcv_id
	ORDER BY
		eq.equipment_name,
		ts.operation_range		
	
	SELECT	stsj.sts_id,
			ts.ts_name,
			stsj.job_employee_id,
			stsj.plan_cnt,
			stsj.employee_cnt,
			stsj.close_cnt,
			stsj.stsj_id,
			stsj.spcvts_id,
			CAST(stsj.close_dt AS DATETIME) close_dt
	FROM	Manufactory.SPCV_TechnologicalSequenceJob stsj   
			INNER JOIN	Manufactory.SPCV_TechnologicalSequence sts
				ON	sts.sts_id = stsj.sts_id   
			INNER JOIN	Planing.SketchPlanColorVariantTS spcvt
				ON	spcvt.spcvts_id = stsj.spcvts_id   
			INNER JOIN	Products.TechSize ts
				ON	ts.ts_id = spcvt.ts_id
	WHERE	sts.spcv_id = @spcv_id