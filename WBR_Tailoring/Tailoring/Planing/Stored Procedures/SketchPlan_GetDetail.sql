CREATE PROCEDURE [Planing].[SketchPlan_GetDetail]
	@sp_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	spcv.spcv_id,
			spcv.spcv_name,
			spcv.qty,
			spcv.comment,
			cvs.cvs_name,
			spcv.cvs_id,
			oa.x completing
	FROM	Planing.SketchPlan sp   
			INNER JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.sp_id = sp.sp_id   
			INNER JOIN	Planing.ColorVariantStatus cvs
				ON	cvs.cvs_id = spcv.cvs_id   
			OUTER APPLY (
			      	SELECT	spcvc.completing_id '@cid',
			      			c.completing_name '@cname',
			      			spcvc.completing_number '@num',
			      			spcvc.rmt_id '@rmid',
			      			rmt.rmt_name '@rmname',
			      			spcvc.comment '@com',
			      			spcvc.frame_width '@fw',
			      			spcvc.okei_id '@okei',
			      			spcvc.consumption '@cm',
			      			o.symbol '@okeiname',
			      			spcvc.color_id '@color',
			      			cc.color_name '@colorname',
			      			spcvc.supplier_id '@sup',
			      			s.supplier_name '@supname'
			      	FROM	Planing.SketchPlanColorVariantCompleting spcvc   
			      			INNER JOIN	Material.Completing c
			      				ON	c.completing_id = spcvc.completing_id   
			      			INNER JOIN	Material.RawMaterialType rmt
			      				ON	rmt.rmt_id = spcvc.rmt_id   
			      			INNER JOIN	Qualifiers.OKEI o
			      				ON	o.okei_id = spcvc.okei_id   
			      			LEFT JOIN	Material.ClothColor cc
			      				ON	cc.color_id = spcvc.color_id
			      			LEFT JOIN Suppliers.Supplier s
			      				ON s.supplier_id = spcvc.supplier_id
			      	WHERE	spcvc.spcv_id = spcv.spcv_id
			      	ORDER BY ISNULL(c.visible_queue, spcvc.completing_id), spcvc.completing_number
			      	FOR XML	PATH('comg'), ROOT('comgs')
			      ) oa(x)
	WHERE	spcv.is_deleted = 0
			AND	spcv.sp_id = @sp_id
	
	SELECT	sc.completing_id,
			c.completing_name,
			sc.completing_number,
			sc.frame_width,
			sc.okei_id,
			o.symbol            okei_symbol,
			sc.consumption,
			sc.comment comment,
			rmt.rmt_name     rmt_name,
			sc.base_rmt_id       rmt_id
	FROM	Planing.SketchPlan sp   
			INNER JOIN	Products.SketchCompleting sc
				ON	sc.sketch_id = sp.sketch_id   
			INNER JOIN	Material.Completing c
				ON	c.completing_id = sc.completing_id   
			INNER JOIN	Qualifiers.OKEI o
				ON	o.okei_id = sc.okei_id 
			INNER JOIN Material.RawMaterialType rmt
				ON rmt.rmt_id = sc.base_rmt_id  
	WHERE	sc.is_deleted = 0
			AND	sp.sp_id = @sp_id
	ORDER BY ISNULL(c.visible_queue, c.completing_id), sc.completing_number
	
	SELECT	sc.completing_id,
			sc.completing_number,
			scrm.rmt_id,
			rmt.rmt_name
	FROM	Planing.SketchPlan sp   
			INNER JOIN	Products.SketchCompleting sc
				ON	sc.sketch_id = sp.sketch_id 
			INNER JOIN	Material.Completing c
				ON	c.completing_id = sc.completing_id   
			INNER JOIN	Products.SketchCompletingRawMaterial scrm
				ON	scrm.sc_id = sc.sc_id   
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = scrm.rmt_id
	WHERE	sp.sp_id = @sp_id
	ORDER BY ISNULL(c.visible_queue, c.completing_id), sc.completing_number