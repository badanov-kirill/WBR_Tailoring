CREATE PROCEDURE [Reports].[ImplementNeedProc]
	@filter_type TINYINT = 1
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	;
	WITH cte AS
	(
		SELECT	rmt.rmt_id,
				rmt.rmt_pid,
				rmt.rmt_name
		FROM	Material.RawMaterialType rmt
		WHERE	rmt.rmt_id = 5
		UNION ALL
		SELECT	rmt.rmt_id,
				rmt.rmt_pid,
				rmt.rmt_name
		FROM	Material.RawMaterialType rmt   
				INNER JOIN	cte c
					ON	c.rmt_id = rmt.rmt_pid
	),
	cte2 AS (
		SELECT	s.sa,
				an.art_name,
				spcvc.rmt_id,
				c.rmt_name,
				spcvc.frame_width,
				cc.color_name,
				spcvc.color_id,
				CASE 
				     WHEN spcvc.cs_id = 1 THEN spcvc.consumption * spcv.qty
				     ELSE 0
				END         qty_need_proc,
				CASE 
				     WHEN spcvc.cs_id = 2 THEN spcvc.consumption * spcv.qty
				     ELSE 0
				END         qty_order,
				oa.cloth_need_processed,
				oa.cloth_order,
				oa.cloth_reserv,
				ct.ct_name,
				ct.ct_id
		FROM	Planing.SketchPlanColorVariantCompleting spcvc   
				INNER JOIN	cte c
					ON	spcvc.rmt_id = c.rmt_id   
				INNER JOIN	Planing.SketchPlanColorVariant spcv
					ON	spcv.spcv_id = spcvc.spcv_id   
				INNER JOIN	Planing.SketchPlan sp
					ON	sp.sp_id = spcv.sp_id   
				INNER JOIN	Products.Sketch s
					ON	s.sketch_id = sp.sketch_id   
				INNER JOIN	Products.ArtName an
					ON	an.art_name_id = s.art_name_id   
				INNER JOIN	Products.[Subject] sj
					ON	sj.subject_id = s.subject_id   
				INNER JOIN	Products.Brand b
					ON	b.brand_id = s.brand_id   
				INNER JOIN	Material.ClothColor cc
					ON	cc.color_id = spcvc.color_id   
				INNER JOIN	Material.ClothType ct
					ON	ct.ct_id = s.ct_id   
				OUTER APPLY (
				      	SELECT	SUM(CASE WHEN spcvc2.cs_id = 2 THEN 1 ELSE 0 END) cloth_order,
				      			SUM(CASE WHEN spcvc2.cs_id = 1 THEN 1 ELSE 0 END) cloth_need_processed,
				      			SUM(CASE WHEN spcvc2.cs_id = 3 THEN 1 ELSE 0 END) cloth_reserv
				      	FROM	Planing.SketchPlanColorVariantCompleting spcvc2   
				      			INNER JOIN	Planing.SketchPlanColorVariant spcv2
				      				ON	spcv2.spcv_id = spcvc2.spcv_id   
				      			INNER JOIN	Material.ClothColor cc2
				      				ON	cc2.color_id = spcvc2.color_id   
				      			INNER JOIN	Material.CompletingIsCloth cic
				      				ON	cic.completing_id = spcvc2.completing_id
				      	WHERE	spcvc2.spcv_id = spcv.spcv_id
				      )     oa
		WHERE	spcvc.cs_id IN (1, 2)
				AND	spcv.is_deleted = 0
				AND	spcv.cvs_id IN (1, 2)
				AND	sp.ps_id NOT IN (4, 3, 8)
				AND	(
				   		(@filter_type = 1 AND oa.cloth_reserv > 0 AND oa.cloth_need_processed = 0 AND oa.cloth_order = 0)
				   		OR (@filter_type = 2 AND oa.cloth_need_processed = 0 AND oa.cloth_order > 0)
				   		OR (@filter_type = 3 AND oa.cloth_need_processed > 0)
				   		OR (@filter_type = 4)
				   	)
	),
	cte3 AS (
		SELECT	c2.rmt_name,
				c2.frame_width,
				c2.color_name,
				SUM(c2.qty_need_proc)     qty_need_proc,
				SUM(c2.qty_order)         qty_order,
				c2.rmt_id,
				c2.color_id,
				c2.ct_name,
				c2.ct_id
		FROM	cte2                      c2
		GROUP BY
			c2.rmt_name,
			c2.frame_width,
			c2.color_name,
			c2.rmt_id,
			c2.color_id,
			c2.ct_name,
			c2.ct_id
	)
	
	SELECT	c3.rmt_name,
			c3.frame_width,
			c3.color_name,
			c3.ct_name,
			c3.qty_need_proc,
			c3.qty_order,
			oa.x models
	FROM	cte3 c3   
			OUTER APPLY (
			      	SELECT	c2.art_name + ' (' + c2.sa + ');'
			      	FROM	cte2 c2
			      	WHERE	c3.rmt_id = c2.rmt_id
			      			AND	ISNULL(c3.frame_width, 0) = ISNULL(c2.frame_width, 0)
			      			AND	c3.color_id = c2.color_id
			      			AND	c3.ct_id = c2.ct_id
			      	FOR XML	PATH('')
			      ) oa(x)