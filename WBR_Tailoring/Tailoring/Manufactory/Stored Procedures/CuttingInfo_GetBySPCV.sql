CREATE PROCEDURE [Manufactory].[CuttingInfo_GetBySPCV]
	@spcv_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	DECLARE @covering_id INT
	
	SELECT	@covering_id = cd.covering_id
	FROM	Planing.CoveringDetail cd
	WHERE	cd.spcv_id = @spcv_id
			AND	cd.is_deleted = 0
	
	SELECT	c.covering_id,
			CAST(c.create_dt AS DATETIME) dt,
			c.create_employee_id
	FROM	Planing.Covering c
	WHERE	c.covering_id = @covering_id
	
	SELECT	isr.shkrm_id,
			rmt.rmt_name,
			smai.frame_width,
			a.art_name,
			cc.color_name,
			isr.stor_unit_residues_qty,
			o2.symbol     stor_unit_residues_okei_symbol,
			oar.reserv_qty,
			0 reserv_qty_for_spcv,
			oaor.our_reserv_qty,
			isr.return_stor_unit_residues_qty,
			CAST(isr.return_dt AS DATETIME) return_dt,
			CASE 
			     WHEN cic.completing_id IS NOT NULL THEN 1
			     ELSE 0
			END is_cloth
	FROM	Planing.CoveringIssueSHKRm isr  
			INNER JOIN	Warehouse.SHKRawMaterialInfo smai
				ON	smai.shkrm_id = isr.shkrm_id   
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = smai.rmt_id   
			INNER JOIN	Material.ClothColor cc
				ON	cc.color_id = smai.color_id   
			INNER JOIN	Material.Article a
				ON	a.art_id = smai.art_id   
			INNER JOIN	Qualifiers.OKEI o2
				ON	o2.okei_id = isr.stor_unit_residues_okei_id  
			LEFT JOIN Material.CompletingRawMaterial crm
				ON crm.rmt_id = rmt.rmt_id
			LEFT JOIN Material.CompletingIsCloth cic
				ON cic.completing_id = crm.completing_id
			OUTER APPLY (
			      	SELECT	SUM(ir.qty) reserv_qty
			      	FROM	Planing.CoveringReserv ir   
			      	WHERE	ir.covering_id = isr.covering_id
			      			AND	ir.shkrm_id = isr.shkrm_id
			      ) oar
			OUTER APPLY (
	      			SELECT	SUM(smr.quantity)      our_reserv_qty
	      			FROM	Warehouse.SHKRawMaterialReserv smr   
	      					LEFT JOIN	Planing.CoveringReserv ir
	      						ON	ir.shkrm_id = smr.shkrm_id
	      						AND	ir.spcvc_id = smr.spcvc_id
	      			WHERE	smr.shkrm_id = isr.shkrm_id
	      					AND	ir.shkrm_id IS     NULL
				  )               oaor
	WHERE	isr.covering_id = @covering_id
	
	SELECT	c.cutting_id,
			pa.sa + pan.sa         sa,
			an.art_name,
			col.color_name,
			sj.subject_name_sf     subject_name,
			b.brand_name,
			ts.ts_name,
			c.perimeter,
			c.plan_count,
			ISNULL(oa_ac.actual_count, 0) actual_count,
			spcv.spcv_id,
			ISNULL(pan.cutting_degree_difficulty, 1) cutting_degree_difficulty,
			s.sketch_id
	FROM	Manufactory.Cutting c   
			INNER JOIN	Planing.SketchPlanColorVariantTS spcvt
				ON	spcvt.spcvts_id = c.spcvts_id   
			INNER JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.spcv_id = spcvt.spcv_id   
			INNER JOIN	Planing.CoveringDetail cd
				ON	cd.spcv_id = spcv.spcv_id   
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
			OUTER APPLY (
			      	SELECT	SUM(ca.actual_count) actual_count
			      	FROM	Manufactory.CuttingActual ca
			      	WHERE	ca.cutting_id = c.cutting_id
			      )                oa_ac
	WHERE	cd.covering_id = @covering_id
			AND	cd.is_deleted = 0
	ORDER BY
		spcv.spcv_id,
		ts.visible_queue,
		ts.ts_name
	
	SELECT	DISTINCT ce.employee_id
	FROM	Manufactory.Cutting c   
			INNER JOIN	Planing.SketchPlanColorVariantTS spcvt
				ON	spcvt.spcvts_id = c.spcvts_id   
			INNER JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.spcv_id = spcvt.spcv_id   
			INNER JOIN	Planing.CoveringDetail cd
				ON	cd.spcv_id = spcv.spcv_id   
			INNER JOIN	Manufactory.CuttingEmployee ce
				ON	ce.cutting_id = c.cutting_id
	WHERE	cd.covering_id = @covering_id
			AND	cd.is_deleted = 0
			
	SELECT	cd.spcv_id,
			tld2.layout_id,
			l.frame_width,
			l.layout_length,
			pa.sa + pan.sa sa,
			c.completing_name + CAST(l.base_completing_number AS VARCHAR(10)) completing,
			l.comment,
			oats.x                       tss,
			oas.x                        added_sketches
	FROM	Planing.CoveringDetail cd   
			OUTER APPLY (
			      	SELECT	TOP(1) tl.tl_id
			      	FROM	Manufactory.TaskLayout tl
			      	WHERE	tl.spcv_id = cd.spcv_id
			      			AND	EXISTS(
			      			   		SELECT	1
			      			   		FROM	Manufactory.TaskLayoutDetail tld
			      			   		WHERE	tld.tl_id = tl.tl_id
			      			   	)
			      	ORDER BY
			      		tl.tl_id DESC
			      ) oa_tl
			INNER JOIN	Manufactory.TaskLayoutDetail tld2
				ON	oa_tl.tl_id = tld2.tl_id   
			INNER JOIN	Manufactory.Layout l
				ON	l.layout_id = tld2.layout_id   
			INNER JOIN Planing.SketchPlanColorVariant spcv
				ON spcv.spcv_id = cd.spcv_id
			LEFT JOIN Products.ProdArticleNomenclature pan
			INNER JOIN Products.ProdArticle pa
				ON pa.pa_id = pan.pa_id
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = pa.sketch_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id			
				ON pan.pan_id = spcv.pan_id			  
			INNER JOIN	Material.Completing c
				ON	c.completing_id = l.base_completing_id
			OUTER APPLY (
			      	SELECT	ts.ts_name + '(' + CAST(CAST(lt.completing_qty AS INT) AS VARCHAR(10)) + '); '
			      	FROM	Manufactory.LayoutTS lt   
			      			INNER JOIN	Products.TechSize ts
			      				ON	ts.ts_id = lt.ts_id
			      	WHERE	lt.layout_id = l.layout_id
			      	FOR XML	PATH('')
			      ) oats(x)
			OUTER APPLY (
			       	SELECT	sj.subject_name + '|' + an.art_name + '|' + s.sa + ';'
			       	FROM	Manufactory.LayoutAddedSketch las   
			       			INNER JOIN	Products.Sketch s
			       				ON	s.sketch_id = las.sketch_id   
			       			INNER JOIN	Products.ArtName an
			       				ON	an.art_name_id = s.art_name_id   
			       			INNER JOIN	Products.[Subject] sj
			       				ON	sj.subject_id = s.subject_id
			       	WHERE	las.layout_id = l.layout_id
			       	FOR XML	PATH('')
			                     ) oas(x)
	WHERE	cd.covering_id = @covering_id
			AND	cd.is_deleted = 0
			AND l.is_deleted = 0
			
	SELECT	ir.shkrm_id,
			spcvc.spcv_id,
			SUM(ir.qty) reserv_qty
	FROM	Planing.CoveringReserv ir   
			INNER JOIN	Planing.SketchPlanColorVariantCompleting spcvc
				ON	spcvc.spcvc_id = ir.spcvc_id
	WHERE	ir.covering_id = @covering_id
	GROUP BY
		ir.shkrm_id,
		spcvc.spcv_id