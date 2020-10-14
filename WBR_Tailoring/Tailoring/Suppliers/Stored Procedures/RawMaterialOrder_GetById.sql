CREATE PROCEDURE [Suppliers].[RawMaterialOrder_GetById]
	@rmo_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	DECLARE @rmod_status_deleted TINYINT = 2 -- удален	
	
	SELECT	rmo.rmo_id,
			CAST(rmo.create_dt AS DATETIME) create_dt,
			rmo.create_employee_id,
			rmo.supplier_id,
			rmo.suppliercontract_id,
			CAST(rmo.supply_dt AS DATETIME) supply_dt,
			rmo.is_deleted,
			rmo.comment,
			rmo.employee_id,
			CAST(rmo.dt AS DATETIME)       dt,
			CAST(rmo.approve_dt AS DATETIME)       approve_dt,
			rmo.approve_employee_id
	FROM	Suppliers.RawMaterialOrder     rmo
	WHERE	rmo.rmo_id = @rmo_id
	
	SELECT	rmodfr.rmodr_id,
			rmt.rmt_name,
			cc.color_name,
			spcvc.comment,
			rmodfr.qty,
			o.symbol okei_symbol,
			rms.frame_width,
			rmodfr.price_cur,
			rmodfr.price_cur * rmodfr.qty amount,
			c.currency_name_shot,
			rmodfr.price_cur * c.rate_absolute price_ru,
			ISNULL(s.imt_name, sj.subject_name) imt_name,
			an.art_name,
			s.sa,
			cg.completing_name,
			spcvc.completing_number,
			spcv.spcv_name,
			rmodfr.rmods_id,
			rmods.rmods_name
	FROM	Suppliers.RawMaterialOrderDetailFromReserv rmodfr   
			INNER JOIN	RefBook.Currency c
				ON	c.currency_id = rmodfr.currency_id   
			INNER JOIN	Suppliers.RawMaterialStockReserv rmsr
				ON	rmsr.rmsr_id = rmodfr.rmsr_id   
			INNER JOIN	Planing.SketchPlanColorVariantCompleting spcvc
				ON	spcvc.spcvc_id = rmsr.spcvc_id   
			INNER JOIN	Material.Completing cg
				ON	cg.completing_id = spcvc.completing_id   
			INNER JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.spcv_id = spcvc.spcv_id   
			INNER JOIN	Planing.SketchPlan sp
				ON	sp.sp_id = spcv.sp_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = sp.sketch_id   
			INNER JOIN	Products.[Subject] sj
				ON	sj.subject_id = s.subject_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id   
			INNER JOIN	Suppliers.RawMaterialStock rms
				ON	rms.rms_id = rmsr.rms_id   
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = rms.rmt_id   
			INNER JOIN	Material.ClothColor cc
				ON	cc.color_id = rms.color_id   
			INNER JOIN	Qualifiers.OKEI o
				ON	o.okei_id = rms.okei_id   
			INNER JOIN	Suppliers.RawMaterialOrderDetailStatus rmods
				ON	rmodfr.rmods_id = rmods.rmods_id
	WHERE	rmodfr.rmo_id = @rmo_id
			AND	rmodfr.rmods_id != @rmod_status_deleted
	
	SELECT	rmod.rmod_id,
			rmt.rmt_name,
			cc.color_name,
			rmod.frame_width,
			rmod.comment,
			rmod.price_cur,
			rmod.price_cur * rmod.qty     amount,
			rmod.price_cur * c.rate_absolute price_ru,
			c.currency_name_shot,
			rmod.qty,
			o.symbol                      okei_symbol,
			rmod.rmods_id,
			rmods.rmods_name,
			rmod.rmt_id,
			rmod.color_id,
			rmod.okei_id,
			rmod.currency_id
	FROM	Suppliers.RawMaterialOrderDetail rmod   
			INNER JOIN	RefBook.Currency c
				ON	c.currency_id = rmod.currency_id   
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = rmod.rmt_id   
			INNER JOIN	Material.ClothColor cc
				ON	cc.color_id = rmod.color_id   
			INNER JOIN	Qualifiers.OKEI o
				ON	o.okei_id = rmod.okei_id   
			INNER JOIN	Suppliers.RawMaterialOrderDetailStatus rmods
				ON	rmod.rmods_id = rmods.rmods_id
	WHERE	rmod.rmo_id = @rmo_id
			AND	rmod.rmods_id != @rmod_status_deleted
	
	SELECT	v.rmt_name,
			v.color_name,
			v.frame_width,
			v.comment,
			v.price_cur,
			v.currency_name_shot,
			SUM(v.qty) qty,
			v.okei_symbol
	FROM	(SELECT	rmt.rmt_name,
	    	 		cc.color_name,
	    	 		rmod.frame_width,
	    	 		rmod.comment,
	    	 		rmod.price_cur,
	    	 		c.currency_name_shot,
	    	 		rmod.qty,
	    	 		o.symbol okei_symbol
	    	 FROM	Suppliers.RawMaterialOrderDetail rmod   
	    	 		INNER JOIN	RefBook.Currency c
	    	 			ON	c.currency_id = rmod.currency_id   
	    	 		INNER JOIN	Material.RawMaterialType rmt
	    	 			ON	rmt.rmt_id = rmod.rmt_id   
	    	 		INNER JOIN	Material.ClothColor cc
	    	 			ON	cc.color_id = rmod.color_id   
	    	 		INNER JOIN	Qualifiers.OKEI o
	    	 			ON	o.okei_id = rmod.okei_id
	    	 WHERE	rmod.rmo_id = @rmo_id
	    	 		AND	rmod.rmods_id != @rmod_status_deleted
	    	UNION ALL	
	    	SELECT	rmt.rmt_name,
	    			cc.color_name,
	    			rms.frame_width,
	    			rms.comment,
	    			rmodfr.price_cur,
	    			c.currency_name_shot,
	    			rmodfr.qty,
	    			o.symbol okei_symbol
	    	FROM	Suppliers.RawMaterialOrderDetailFromReserv rmodfr   
	    			INNER JOIN	RefBook.Currency c
	    				ON	c.currency_id = rmodfr.currency_id   
	    			INNER JOIN	Suppliers.RawMaterialStockReserv rmsr
	    				ON	rmsr.rmsr_id = rmodfr.rmsr_id   
	    			INNER JOIN	Suppliers.RawMaterialStock rms
	    				ON	rms.rms_id = rmsr.rms_id   
	    			INNER JOIN	Material.RawMaterialType rmt
	    				ON	rmt.rmt_id = rms.rmt_id   
	    			INNER JOIN	Material.ClothColor cc
	    				ON	cc.color_id = rms.color_id   
	    			INNER JOIN	Qualifiers.OKEI o
	    				ON	o.okei_id = rms.okei_id
	    	WHERE	rmodfr.rmo_id = @rmo_id
	    			AND	rmodfr.rmods_id != @rmod_status_deleted)v
	GROUP BY
		v.rmt_name,
		v.color_name,
		v.frame_width,
		v.comment,
		v.price_cur,
		v.currency_name_shot,
		v.okei_symbol 
		
		
		