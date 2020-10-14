CREATE PROCEDURE [Products].[Nomenclature_Statistics_GetBySketch]
	@sketch_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	v.sa,
			v.nm_id,
			ns.sale_qty,
			ns.sale_amount,
			ns.turnover,
			ns.effective_percent_discount,
			ns.income_qty,
			ns.ordered_qty,
			vs.shipping_dt,
			v.whprice
	FROM	(SELECT	pa.sa + pan.sa sa,
	    	 		pan.nm_id,
	    	 		pan.whprice
	    	 FROM	Products.Sketch s   
	    	 		INNER JOIN	Products.ProdArticle pa
	    	 			ON	pa.sketch_id = s.sketch_id   
	    	 		INNER JOIN	Products.ProdArticleNomenclature pan
	    	 			ON	pan.pa_id = pa.pa_id
	    	 WHERE	s.sketch_id = @sketch_id
	    	 		AND	((pa.is_deleted = 0 AND pan.is_deleted = 0))
	    	UNION 
	    	SELECT	eis.sa + ens.sa sa,
	    			ens.nm_id,
	    			0
	    	FROM	Products.ERP_IMT_Sketch eis   
	    			INNER JOIN	Products.ERP_NM_Sketch ens
	    				ON	ens.imt_id = eis.imt_id
	    	WHERE	eis.sketch_id = @sketch_id)v   
			LEFT JOIN	Products.Nomenclature_Statistics ns
				ON	ns.nm_id = v.nm_id
			LEFT JOIN	(SELECT	pan.nm_id,
		    	    	 		CAST(MIN(sfp.complite_dt) AS DATETIME) shipping_dt
		    	    	 FROM	Logistics.TransferBoxDetail tbd   
		    	    	 		INNER JOIN	Manufactory.ProductUnicCode puc
		    	    	 			ON	puc.product_unic_code = tbd.product_unic_code   
		    	    	 		INNER JOIN	Products.ProdArticleNomenclatureTechSize pants
		    	    	 			ON	pants.pants_id = puc.pants_id   
		    	    	 		INNER JOIN	Products.ProdArticleNomenclature pan
		    	    	 			ON	pan.pan_id = pants.pan_id   
		    	    	 		INNER JOIN	Logistics.ShipmentFinishedProductsDetail sfpd
		    	    	 			ON	sfpd.transfer_box_id = tbd.transfer_box_id   
		    	    	 		INNER JOIN	Logistics.ShipmentFinishedProducts sfp
		    	    	 			ON	sfp.sfp_id = sfpd.sfp_id
		    	    	 GROUP BY
		    	    	 	pan.nm_id)vs
			ON	ns.nm_id = vs.nm_id
