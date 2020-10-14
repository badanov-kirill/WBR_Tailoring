CREATE PROCEDURE [Reports].[SketchPlanForPaymentDetail]
	@sp_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	spcv.spcv_id,
			spcv.spcv_name,
			spcv.qty                         cv_qty,
			spcv.comment cv_comment,
			c.completing_name,
			spcvc.completing_number,			
			rmt.rmt_name,
			spcvc.consumption,
			o.symbol,
			spcvc.consumption * spcv.qty     qty,
			spcvc.comment                    rm_comment,
			v.price,
			cc.color_name
	FROM	Planing.SketchPlanColorVariantCompleting spcvc 
			INNER JOIN Material.ClothColor cc
				ON cc.color_id = spcvc.color_id  
			INNER JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.spcv_id = spcvc.spcv_id   
			INNER JOIN	Material.Completing c
				ON	c.completing_id = spcvc.completing_id   
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = spcvc.rmt_id   
			INNER JOIN	Qualifiers.OKEI o
				ON	o.okei_id = spcvc.okei_id   
			LEFT JOIN	(SELECT	rmsr.spcvc_id,
			    	    	 		MAX(rmodr.price_cur * cur.rate_absolute) price
			    	    	 FROM	Suppliers.RawMaterialStockReserv rmsr   
			    	    	 		INNER JOIN	Suppliers.RawMaterialOrderDetailFromReserv rmodr
			    	    	 			ON	rmodr.rmsr_id = rmsr.rmsr_id   
			    	    	 		INNER JOIN	RefBook.Currency cur
			    	    	 			ON	cur.currency_id = rmodr.currency_id
			    	    	 GROUP BY
			    	    	 	rmsr.spcvc_id)v
				ON	v.spcvc_id = spcvc.spcvc_id
	WHERE	spcv.sp_id = @sp_id
	ORDER BY
		spcv.spcv_id,
		spcvc.consumption * spcv.qty * v.price DESC,
		spcvc.completing_id,
		spcvc.completing_number