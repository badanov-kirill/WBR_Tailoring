CREATE PROCEDURE [Warehouse].[SHKRawMaterialIssue_FindByShk]
	@shkrm_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	mipds.shkrm_id,
			sma.amount * mipds.stor_unit_residues_qty / sma.stor_unit_residues_qty amount,
			rmt.rmt_name,
			smai.rmt_id,
			smai.art_id,
			a.art_name,
			mipds.qty,
			mipds.okei_id,
			o.symbol                       okei_symbol,
			mipds.stor_unit_residues_qty,
			o2.symbol                      stor_unit_residues_okei_symbol,
			oa.x                           articles,
			CAST(mipds.dt AS DATETIME)     issue_dt,
			mipds.mip_id,
			NULL                           covering_id,
			NULL                           sketch_id
	FROM	Warehouse.MaterialInProductionDetailShk mipds   
			INNER JOIN	Warehouse.MaterialInProduction mip
				ON	mip.mip_id = mipds.mip_id   
			INNER JOIN	Warehouse.SHKRawMaterialActualInfo smai
				ON	smai.shkrm_id = mipds.shkrm_id   
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = smai.rmt_id   
			INNER JOIN	Material.Article a
				ON	a.art_id = smai.art_id   
			INNER JOIN	Qualifiers.OKEI o
				ON	o.okei_id = mipds.okei_id   
			INNER JOIN	Qualifiers.OKEI o2
				ON	o2.okei_id = mipds.stor_unit_residues_okei_id   
			INNER JOIN	Warehouse.SHKRawMaterialAmount sma
				ON	sma.shkrm_id = mipds.shkrm_id   
			OUTER APPLY (
			      	SELECT	pa.sa + pan.sa + ' '
			      	FROM	Warehouse.MaterialInProductionDetailNom mipdn   
			      			INNER JOIN	Products.ProdArticleNomenclature pan
			      				ON	pan.pan_id = mipdn.pan_id   
			      			INNER JOIN	Products.ProdArticle pa
			      				ON	pa.pa_id = pan.pa_id
			      	WHERE	mipdn.mip_id = mip.mip_id
			      	FOR XML	PATH('')
			      ) oa(x)
	WHERE	mipds.shkrm_id = @shkrm_id
			AND	mip.complite_dt IS NULL
			AND	mipds.return_dt IS         NULL
	UNION ALL
	SELECT	isr.shkrm_id,
			sma.amount * isr.stor_unit_residues_qty / sma.stor_unit_residues_qty amount,
			rmt.rmt_name,
			smai.rmt_id,
			smai.art_id,
			a.art_name,
			isr.qty,
			isr.okei_id,
			o.symbol                 okei_symbol,
			isr.stor_unit_residues_qty,
			o2.symbol                stor_unit_residues_okei_symbol,
			oa.x                     articles,
			CAST(isr.dt AS DATETIME),
			NULL,
			isr.covering_id,
			NULL                     sketch_id
	FROM	Planing.CoveringIssueSHKRm isr   
			INNER JOIN	Warehouse.SHKRawMaterialActualInfo smai
				ON	smai.shkrm_id = isr.shkrm_id   
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = smai.rmt_id   
			INNER JOIN	Warehouse.SHKRawMaterialAmount sma
				ON	sma.shkrm_id = isr.shkrm_id   
			INNER JOIN	Material.Article a
				ON	a.art_id = smai.art_id   
			INNER JOIN	Qualifiers.OKEI o
				ON	o.okei_id = isr.okei_id   
			INNER JOIN	Qualifiers.OKEI o2
				ON	o2.okei_id = isr.stor_unit_residues_okei_id   
			OUTER APPLY (
			      	SELECT	v.sa
			      	FROM	(SELECT	pa.sa + pan.sa + ' ' sa
			      	    	 FROM	Planing.CoveringDetail cd   
			      	    	 		INNER JOIN	Planing.SketchPlanColorVariant spcv
			      	    	 			ON	spcv.spcv_id = cd.spcv_id   
			      	    	 		INNER JOIN	Products.ProdArticleNomenclature pan
			      	    	 			ON	pan.pan_id = spcv.pan_id   
			      	    	 		INNER JOIN	Products.ProdArticle pa
			      	    	 			ON	pa.pa_id = pan.pa_id
			      	    	 WHERE	cd.covering_id = isr.covering_id)v(sa)
			      	FOR XML	PATH('')
			      ) oa(x)
	WHERE	isr.shkrm_id = @shkrm_id
			AND	isr.return_dt IS     NULL
	UNION ALL
	SELECT	mis.shkrm_id,
			sma.amount * mis.stor_unit_residues_qty / sma.stor_unit_residues_qty amount,
			rmt.rmt_name,
			smai.rmt_id,
			smai.art_id,
			a.art_name,
			mis.qty,
			mis.okei_id,
			o.symbol                 okei_symbol,
			mis.stor_unit_residues_qty,
			o2.symbol                stor_unit_residues_okei_symbol,
			s.sa + ' (' + an.art_name + ')' articles,
			CAST(mis.dt AS DATETIME),
			NULL,
			NULL,
			mis.sketch_id            sketch_id
	FROM	Warehouse.MaterialInSketch mis   
			INNER JOIN	Warehouse.SHKRawMaterialActualInfo smai
				ON	smai.shkrm_id = mis.shkrm_id   
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = smai.rmt_id   
			INNER JOIN	Warehouse.SHKRawMaterialAmount sma
				ON	sma.shkrm_id = mis.shkrm_id   
			INNER JOIN	Material.Article a
				ON	a.art_id = smai.art_id   
			INNER JOIN	Qualifiers.OKEI o
				ON	o.okei_id = mis.okei_id   
			INNER JOIN	Qualifiers.OKEI o2
				ON	o2.okei_id = mis.stor_unit_residues_okei_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = mis.sketch_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id
	WHERE	mis.shkrm_id = @shkrm_id
			AND	mis.return_dt IS     NULL