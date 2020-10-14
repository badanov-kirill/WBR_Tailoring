CREATE PROCEDURE [Planing].[Covering_GetInfoForCost]
	@covering_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	
	SELECT	cd.cd_id,
			cd.spcv_id,
			an.art_name,
			pa.sa + pan.sa     sa,
			c.color_name,
			oa_ac.actual_count,
			s.sketch_id,
			oap.price_ru,
			pan.nm_id,
			oa_ac.cutting_cost * ISNULL(pan.cutting_degree_difficulty, 1) cutting_cost
	FROM	Planing.CoveringDetail cd   
			INNER JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.spcv_id = cd.spcv_id   
			INNER JOIN	Products.ProdArticleNomenclature pan
				ON	pan.pan_id = spcv.pan_id   
			INNER JOIN	Products.ProdArticle pa
				ON	pa.pa_id = pan.pa_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = pa.sketch_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id   
			LEFT JOIN	Products.ProdArticleNomenclatureColor panc   
			INNER JOIN	Products.Color c
				ON	c.color_cod = panc.color_cod
				ON	panc.pan_id = pan.pan_id
				AND	panc.is_main = 1   
			OUTER APPLY (
			      	SELECT	ISNULL(SUM(ca.actual_count), 0) actual_count,
			      			ISNULL(SUM(ca.actual_count * cut.perimeter * cut.cutting_tariff), 0) cutting_cost
			      	FROM	Planing.SketchPlanColorVariantTS spcvt   
			      			INNER JOIN	Manufactory.Cutting cut
			      				ON	cut.spcvts_id = spcvt.spcvts_id   
			      			INNER JOIN	Manufactory.CuttingActual ca
			      				ON	ca.cutting_id = cut.cutting_id
			      	WHERE	spcvt.spcv_id = spcv.spcv_id
			      ) oa_ac			
			OUTER APPLY (
	      			SELECT	TOP(1) pan2.price_ru
	      			FROM	Products.ProdArticleNomenclature pan2
	      			WHERE	pan2.pa_id = pan.pa_id
	      			ORDER BY
	      				pan2.price_ru DESC
				  )                    oap
	WHERE	cd.covering_id = @covering_id
			AND	s.is_deleted = 0
	
	SELECT	spcvc.spcv_id,
			spcvc.spcvc_id,
			c.completing_name + ' ' + CAST(spcvc.completing_number AS VARCHAR(10)) completing,
			cr.shkrm_id,
			rmt.rmt_name,
			smai.frame_width,
			o.symbol        stor_unit_residues_okei_symbol,
			cc.color_name,
			cr.qty,
			a.art_name,
			sp.sketch_id,
			an.art_name     s_art_name
	FROM	Planing.CoveringReserv cr   
			INNER JOIN	Planing.SketchPlanColorVariantCompleting spcvc
				ON	spcvc.spcvc_id = cr.spcvc_id   
			INNER JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.spcv_id = spcvc.spcv_id   
			INNER JOIN	Planing.SketchPlan sp
				ON	sp.sp_id = spcv.sp_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = sp.sketch_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id   
			INNER JOIN	Material.Completing c
				ON	c.completing_id = spcvc.completing_id   
			INNER JOIN	Warehouse.SHKRawMaterialInfo smai
				ON	smai.shkrm_id = cr.shkrm_id   
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = smai.rmt_id   
			INNER JOIN	Material.ClothColor cc
				ON	cc.color_id = smai.color_id   
			INNER JOIN	Material.Article a
				ON	a.art_id = smai.art_id   
			INNER JOIN	Qualifiers.OKEI o
				ON	o.okei_id = cr.okei_id
	WHERE	cr.covering_id = @covering_id	
	
	SELECT	cis.shkrm_id,
			rmt.rmt_name,
			smai.frame_width,
			a.art_name,
			cc.color_name,
			cis.stor_unit_residues_qty,
			o2.symbol           stor_unit_residues_okei_symbol,
			CAST(cis.return_dt AS DATETIME) return_dt,
			cis.return_stor_unit_residues_qty return_qty,
			cis.stor_unit_residues_qty - ISNULL(cis.return_stor_unit_residues_qty, 0) spent_qty,
			sma.amount / sma.stor_unit_residues_qty price,
			sma.amount * (cis.stor_unit_residues_qty - ISNULL(cis.return_stor_unit_residues_qty, 0)) / sma.stor_unit_residues_qty spent_amount,
			CAST(sma.final_dt AS DATETIME) final_dt,
			rmi.employee_id     rmi_employee_id,
			rmi.doc_id
	FROM	Planing.CoveringIssueSHKRm cis   
			INNER JOIN	Warehouse.SHKRawMaterialInfo smai
				ON	smai.shkrm_id = cis.shkrm_id   
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = smai.rmt_id   
			INNER JOIN	Material.ClothColor cc
				ON	cc.color_id = smai.color_id   
			INNER JOIN	Material.Article a
				ON	a.art_id = smai.art_id   
			INNER JOIN	Qualifiers.OKEI o2
				ON	o2.okei_id = cis.stor_unit_residues_okei_id   
			INNER JOIN	Warehouse.SHKRawMaterialAmount sma
				ON	sma.shkrm_id = cis.shkrm_id   
			LEFT JOIN	Material.RawMaterialIncome rmi
				ON	rmi.doc_id = smai.doc_id
				AND	rmi.doc_type_id = smai.doc_type_id
	WHERE	cis.covering_id = @covering_id