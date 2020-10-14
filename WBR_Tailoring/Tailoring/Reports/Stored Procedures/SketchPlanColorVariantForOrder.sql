CREATE PROCEDURE [Reports].[SketchPlanColorVariantForOrder]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	DECLARE @status_bayer TINYINT = 5
	DECLARE @status_bayer_repeat TINYINT = 7
	DECLARE @states_approve TINYINT = 2
	DECLARE @status_bayer_to_designer TINYINT = 6
	DECLARE @status_processed_bayer TINYINT = 8
	DECLARE @status_complite TINYINT = 4
	
	SELECT	sp.plan_year,
			sp.plan_month,
			ct.ct_name,
			an.art_name,
			ISNULL(s.imt_name, sj.subject_name_sf) imt_name,
			s.sa,
			pa.sa + pan.sa sa_nm,
			b.brand_name,
			spcv.spcv_name,
			spcv.qty                         cv_qty,
			c.completing_name + ' ' + CAST(spcvc.completing_number AS VARCHAR(10)) completing,
			rmt.rmt_name,
			cc.color_name,
			ISNULL(spcvc.frame_width, 0)     frame_width,
			spcvc.consumption,
			spcv.qty * CAST(spcvc.consumption AS DECIMAL(17, 3)) qty,
			o.symbol                         okei_symbol,
			oa_res.qty_reserv,
			cs.cs_name,
			oa_res.order_id,
			psg.psg_name,
			CAST(spcv.dt AS DATETIME) spcv_dt,
			CAST(spcvc.dt AS DATETIME) spcvc_dt,
			spcvc.comment
	FROM	Planing.SketchPlan sp   
			INNER JOIN Planing.PlanStatus ps
				ON ps.ps_id = sp.ps_id
			INNER JOIN Planing.PlanStatusGroup psg
				ON psg.psg_id = ps.psg_id
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = sp.sketch_id   
			LEFT JOIN	Material.ClothType ct
				ON	ct.ct_id = s.ct_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id   
			INNER JOIN	Products.[Subject] sj
				ON	sj.subject_id = s.subject_id   
			INNER JOIN	Products.Brand b
				ON	b.brand_id = s.brand_id   
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
			INNER JOIN	Planing.CompletingStatus cs
				ON	cs.cs_id = spcvc.cs_id
			LEFT JOIN Products.ProdArticleNomenclature pan
			INNER JOIN Products.ProdArticle pa
				ON	pa.pa_id = pan.pa_id
				ON	pan.pan_id = spcv.pan_id
			OUTER APPLY (
			      	SELECT	SUM(rmsr.qty) qty_reserv,
			      			MAX(rmodfr.rmo_id) order_id
			      	FROM	Suppliers.RawMaterialStockReserv rmsr   
			      			INNER JOIN	Suppliers.RawMaterialStock rms
			      				ON	rms.rms_id = rmsr.rms_id   
			      			LEFT JOIN	Suppliers.RawMaterialOrderDetailFromReserv rmodfr
			      				ON	rmodfr.rmsr_id = rmsr.rmsr_id
			      				AND	rmodfr.rmods_id != 2
			      	WHERE	rmsr.spcvc_id = spcvc.spcvc_id
			      )                          oa_res
	WHERE	sp.ps_id IN (@status_bayer, @status_bayer_repeat, @states_approve, @status_bayer_to_designer, @status_processed_bayer, @status_complite)
			AND	spcv.is_deleted = 0
	ORDER BY
		sp.dt DESC,
		sp.sp_id,
		spcv.spcv_id,
		spcvc.completing_id,
		spcvc.completing_number




