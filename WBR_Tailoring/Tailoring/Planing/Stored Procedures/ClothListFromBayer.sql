CREATE PROCEDURE [Planing].[ClothListFromBayer]
	@color_id INT = NULL,
	@rmt_id INT = NULL,
	@plan_year SMALLINT = NULL,
	@plan_month TINYINT = NULL,
	@ct_id INT = NULL,
	@brand_id INT = NULL,
	@office_id INT = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	
	DECLARE @status_bayer TINYINT = 5
	DECLARE @status_bayer_repeat TINYINT = 7
	DECLARE @cvc_state_need_proc TINYINT = 1
	
	SELECT	rmt.rmt_name,
			rmt.rmt_id,
			cc.color_name,
			cc.color_id,
			o.symbol             okei_symbol,
			SUM(spcv.qty * CAST(spcvc.consumption AS DECIMAL(17, 3))) qty,
			ISNULL(t.qty, 0)     stock_qty,
			CAST(MAX(spcv.dt) AS DATETIME) max_dt,
			spcvc.frame_width
	FROM	Planing.SketchPlan sp 
			INNER JOIN Products.Sketch s
				ON s.sketch_id = sp.sketch_id  
			INNER JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.sp_id = sp.sp_id   
			INNER JOIN	Planing.SketchPlanColorVariantCompleting spcvc
				ON	spcvc.spcv_id = spcv.spcv_id   
			LEFT JOIN	Material.ClothColor cc
				ON	cc.color_id = spcvc.color_id   
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = spcvc.rmt_id   
			INNER JOIN	Qualifiers.OKEI o
				ON	o.okei_id = spcvc.okei_id   
			INNER JOIN	Material.Completing c
				ON	c.completing_id = spcvc.completing_id   
			LEFT JOIN	(SELECT	rms.rmt_id,
			    	    	 		rms.color_id,
			    	    	 		rms.okei_id,
			    	    	 		SUM(rms.qty) qty
			    	    	 FROM	Suppliers.RawMaterialStock rms
			    	    	 WHERE	rms.end_dt_offer > @dt
			    	    	 GROUP BY
			    	    	 	rms.rmt_id,
			    	    	 	rms.color_id,
			    	    	 	rms.okei_id)t
				ON	t.rmt_id = spcvc.rmt_id
				AND	t.color_id = spcvc.color_id
				AND	t.okei_id = spcvc.okei_id
	WHERE	sp.ps_id IN (@status_bayer, @status_bayer_repeat)
			AND	spcvc.cs_id = @cvc_state_need_proc
			AND	(@color_id IS NULL OR spcvc.color_id = @color_id)
			AND	(@rmt_id IS NULL OR spcvc.rmt_id = @rmt_id)
			AND spcv.is_deleted = 0
			AND (@plan_year IS NULL OR sp.plan_year = @plan_year)
			AND (@plan_month IS NULL OR sp.plan_month = @plan_month)
			AND (@ct_id IS NULL OR s.ct_id = @ct_id)
			AND (@brand_id IS NULL OR s.brand_id = @brand_id)
			AND (@office_id IS NULL OR sp.sew_office_id = @office_id)
	GROUP BY
		rmt.rmt_name,
		rmt.rmt_id,
		cc.color_name,
		cc.color_id,
		o.symbol,
		t.qty,
		spcvc.frame_width
