CREATE PROCEDURE [Planing].[SketchPlanColorVariant_GetColorInfo]
	@spcv_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	c.completing_name + ' ' + CAST(spcvc.completing_number AS VARCHAR(10)) completing,
			spcvc.comment,
			spcvc.consumption                consumption,
			o.symbol                         okei_symbol,
			oar.qty                          reserv_qty,
			ISNULL(oa_rmt_res.x, ISNULL(oa_rmt_order.x, rmt.rmt_name + '(' + cc.color_name + ')')) color
	FROM	Planing.SketchPlanColorVariantCompleting spcvc   
			INNER JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.spcv_id = spcvc.spcv_id   
			INNER JOIN	Material.Completing c
				ON	c.completing_id = spcvc.completing_id   
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = spcvc.rmt_id   
			INNER JOIN	Qualifiers.OKEI o
				ON	o.okei_id = spcvc.okei_id   
			LEFT JOIN	Material.ClothColor cc
				ON	cc.color_id = spcvc.color_id   
			LEFT JOIN	Material.CompletingIsCloth cic
				ON	cic.completing_id = c.completing_id   
			OUTER APPLY (
			      	SELECT	SUM(smr.quantity) qty
			      	FROM	Warehouse.SHKRawMaterialReserv smr
			      	WHERE	smr.spcvc_id = spcvc.spcvc_id
			      ) oar
			OUTER APPLY (
	      			SELECT	v.rmt_name + '(' + v.art_name + '(' + v.color_name + ')); '
	      			FROM	(SELECT	rmt2.rmt_name,
	      	    	 				a.art_name,
	      	    	 				cc2.color_name
	      	    			 FROM	Warehouse.SHKRawMaterialReserv smr   
	      	    	 				INNER JOIN	Warehouse.SHKRawMaterialActualInfo smai
	      	    	 					ON	smai.shkrm_id = smr.shkrm_id   
	      	    	 				INNER JOIN	Material.Article a
	      	    	 					ON	a.art_id = smai.art_id   
	      	    	 				INNER JOIN	Material.RawMaterialType rmt2
	      	    	 					ON	rmt2.rmt_id = smai.rmt_id   
	      	    	 				INNER JOIN	Material.ClothColor cc2
	      	    	 					ON	cc2.color_id = smai.color_id
	      	    			 WHERE	smr.spcvc_id = spcvc.spcvc_id
	      	    			 GROUP BY
	      	    	 			rmt2.rmt_name,
	      	    	 			a.art_name,
	      	    	 			cc2.color_name)v
	      			FOR XML	PATH('')
				) oa_rmt_res(x)
	      OUTER APPLY (
	                SELECT	v.rmt_name + '(' + v.color_name + '); '
	                FROM	(SELECT	rmt3.rmt_name,
	                    	 		cc3.color_name
	                    	 FROM	Suppliers.RawMaterialOrderDetailFromReserv smr   
	                    	 		INNER JOIN	Suppliers.RawMaterialStockReserv rmsr
	                    	 			ON	rmsr.rmsr_id = smr.rmsr_id   
	                    	 		INNER JOIN	Suppliers.RawMaterialStock rms
	                    	 			ON	rms.rms_id = rmsr.rms_id   
	                    	 		INNER JOIN	Material.RawMaterialType rmt3
	                    	 			ON	rmt3.rmt_id = rms.rmt_id   
	                    	 		INNER JOIN	Material.ClothColor cc3
	                    	 			ON	cc3.color_id = rms.color_id
	                    	 WHERE	rmsr.spcvc_id = spcvc.spcvc_id
	                    	 		AND	smr.rmods_id != 2
	                    	 GROUP BY
	                    	 	rmt3.rmt_name,
	                    	 	cc3.color_name)v
	                FOR XML	PATH('')
	         ) oa_rmt_order(x)
	WHERE	spcvc.spcv_id = @spcv_id
			AND	cic.completing_id IS NOT     NULL
	ORDER BY
		spcvc.completing_id,
		spcvc.completing_number