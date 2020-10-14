CREATE PROCEDURE [Suppliers].[RawMaterialStockReserv_Get]
	@employee_id INT = NULL,
	@art_name VARCHAR(50) = NULL,
	@plan_year SMALLINT = NULL,
	@plan_month TINYINT = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @cvc_state_need_proc TINYINT = 1
	
	SELECT	rms.supplier_id,
			s.supplier_name,
			rmt.rmt_name,
			rms.rmt_id,
			rms.color_id,
			cc.color_name,
			rms.rms_id,
			rms.frame_width,
			rms.qty,
			o.symbol          okei_symbol,
			rms.price_cur,
			c.currency_name_shot,
			rms.price_cur * c.rate_absolute price_ru,
			rms.nds,
			rms.days_delivery_time,
			CAST(rms.end_dt_offer AS DATETIME) end_dt_offer,
			rms.comment,
			rmsr.rmsr_id,
			rmsr.qty          reserv_qty,
			sk.sa,
			an.art_name,
			ISNULL(sk.imt_name, sj.subject_name_sf) imt_name,
			spcv.spcv_name,
			rmsr.spcvc_id,
			cmp.completing_name,
			spcvc.completing_number,
			spcvc.comment     rm_comment,
			sp.plan_year,
			sp.plan_month
	FROM	Suppliers.RawMaterialStockReserv rmsr   
			INNER JOIN	Planing.SketchPlanColorVariantCompleting spcvc
				ON	spcvc.spcvc_id = rmsr.spcvc_id  
			LEFT JOIN Suppliers.RawMaterialOrderDetailFromReserv rmodfr
				ON rmodfr.rmsr_id = rmsr.rmsr_id 
			INNER JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.spcv_id = spcvc.spcv_id   
			INNER JOIN	Material.Completing cmp
				ON	cmp.completing_id = spcvc.completing_id   
			INNER JOIN	Planing.SketchPlan sp
				ON	sp.sp_id = spcv.sp_id   
			INNER JOIN	Products.Sketch sk
				ON	sk.sketch_id = sp.sketch_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = sk.art_name_id   
			INNER JOIN	Products.[Subject] sj
				ON	sj.subject_id = sk.subject_id   
			INNER JOIN	Suppliers.RawMaterialStock rms
				ON	rms.rms_id = rmsr.rms_id   
			INNER JOIN	Suppliers.Supplier s
				ON	s.supplier_id = rms.supplier_id   
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = rms.rmt_id   
			LEFT JOIN	Material.ClothColor cc
				ON	cc.color_id = rms.color_id   
			INNER JOIN	Qualifiers.OKEI o
				ON	o.okei_id = rms.okei_id   
			INNER JOIN	RefBook.Currency c
				ON	c.currency_id = rms.currency_id
	WHERE	rms.end_dt_offer > @dt
			AND	spcvc.cs_id = @cvc_state_need_proc
			AND	spcv.is_deleted = 0
			AND (@employee_id IS NULL OR rmsr.employee_id = @employee_id)
			AND (@art_name IS NULL OR an.art_name LIKE @art_name + '%')
			AND (@plan_year IS NULL OR sp.plan_year = @plan_year)
			AND (@plan_month IS NULL OR sp.plan_month = @plan_month)
			AND rmodfr.rmsr_id IS NULL
	ORDER BY
		s.supplier_name,
		s.supplier_id,
		rmt.rmt_name,
		rms.rmt_id,
		cc.color_name,
		rms.color_id,
		rms.rms_id