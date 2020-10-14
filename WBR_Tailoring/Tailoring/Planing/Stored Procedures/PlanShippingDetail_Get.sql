CREATE PROCEDURE [Planing].[PlanShippingDetail_Get]
	@ps_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	psd.shkrm_id,
			sp.place_name,
			rmt.rmt_name,
			a.art_name,
			cc.color_name,
			smai.frame_width,
			psd.stor_unit_residues_qty     qty,
			o.symbol                       okei_symbol,
			CAST(psd.gross_mass AS DECIMAL(9, 1)) / 1000 gross_mass,
			oap.x                          sketch_info,
			psd.ttnd_id,
			os.office_name,
			oar.qty                        reserv_qty
	FROM	Planing.PlanShippingDetail psd   
			INNER JOIN	Planing.PlanShipping ps
				ON	ps.ps_id = psd.ps_id   
			LEFT JOIN	Warehouse.SHKRawMaterialOnPlace smop   
			INNER JOIN	Warehouse.StoragePlace sp
				ON	sp.place_id = smop.place_id   
			INNER JOIN	Warehouse.ZoneOfResponse zor
				ON	zor.zor_id = sp.zor_id   
			INNER JOIN	Settings.OfficeSetting os
				ON	os.office_id = zor.office_id
				ON	smop.shkrm_id = psd.shkrm_id   
			INNER JOIN	Warehouse.SHKRawMaterialInfo smai
				ON	smai.shkrm_id = psd.shkrm_id   
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = smai.rmt_id   
			INNER JOIN	Material.ClothColor cc
				ON	cc.color_id = smai.color_id   
			INNER JOIN	Material.Article a
				ON	a.art_id = smai.art_id   
			INNER JOIN	Qualifiers.OKEI o
				ON	o.okei_id = psd.stor_unit_residues_okei_id   
			OUTER APPLY (
			      	SELECT	an2.art_name + '|' + FORMAT(smr2.quantity, '0.0') + '(' + ISNULL(pa2.sa + pan2.sa, 'не связан') + '); '
			      	FROM	Warehouse.SHKRawMaterialReserv smr2   
			      			INNER JOIN	Planing.SketchPlanColorVariantCompleting spcvc2
			      				ON	spcvc2.spcvc_id = smr2.spcvc_id   
			      			INNER JOIN	Planing.SketchPlanColorVariant spcv2
			      				ON	spcv2.spcv_id = spcvc2.spcv_id   
			      			LEFT JOIN	Products.ProdArticleNomenclature pan2   
			      			INNER JOIN	Products.ProdArticle pa2
			      				ON	pa2.pa_id = pan2.pa_id
			      				ON	pan2.pan_id = spcv2.pan_id   
			      			INNER JOIN	Planing.SketchPlan sp2
			      				ON	sp2.sp_id = spcv2.sp_id   
			      			INNER JOIN	Products.Sketch s2
			      				ON	s2.sketch_id = sp2.sketch_id   
			      			INNER JOIN	Products.ArtName an2
			      				ON	an2.art_name_id = s2.art_name_id
			      	WHERE	smr2.shkrm_id = psd.shkrm_id
			      	FOR XML	PATH('')
			      ) oap(x)OUTER APPLY (
			                    	SELECT	SUM(smr3.quantity) qty
			                    	FROM	Warehouse.SHKRawMaterialReserv smr3   
			                    			INNER JOIN	Planing.SketchPlanColorVariantCompleting spcvc3
			                    				ON	spcvc3.spcvc_id = smr3.spcvc_id   
			                    			INNER JOIN	Planing.SketchPlanColorVariant spcv3
			                    				ON	spcv3.spcv_id = spcvc3.spcv_id
			                    	WHERE	spcv3.sew_office_id = ps.dst_office_id
			                    			AND	smr3.shkrm_id = psd.shkrm_id
			                    			AND	spcv3.pan_id IS NOT NULL
			                    )          oar
	WHERE	psd.ps_id = @ps_id
	ORDER BY
		CASE 
		     WHEN psd.ttnd_id IS NULL THEN 0
		     ELSE 1
		END,
		rmt.rmt_name,
		smai.color_id,
		smai.art_id