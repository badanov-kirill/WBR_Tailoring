CREATE PROCEDURE [Planing].[ModelClothFromReserv]
	@color_id INT = NULL,
	@rmt_id INT = NULL,
	@brand_id INT = NULL,
	@ct_id INT = NULL,
	@plan_year SMALLINT = NULL,
	@plan_month TINYINT = NULL,
	@spcvc_state_id TINYINT = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	DECLARE @status_processed_bayer TINYINT = 8
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @rmod_status_deleted TINYINT = 2 -- удален
	
	SELECT	s.sketch_id,
			sp.sp_id,
			sp.ps_id,
			an.art_name,
			ISNULL(s.imt_name, sj.subject_name_sf) imt_name,
			s.sa,
			b.brand_name,
			spcv.spcv_name,
			spcv.spcv_id,
			c.completing_name,
			spcvc.completing_number,
			spcvc.spcvc_id,
			ISNULL(oa_res.rmt_name, rmt.rmt_name) rmt_name,
			ISNULL(oa_res.rmt_id, rmt.rmt_id) rmt_id,
			ISNULL(oa_res.color_name, cc.color_name) color_name,
			ISNULL(oa_res.color_id, cc.color_id) color_id,
			ISNULL(spcvc.frame_width, 0)     frame_width,
			o.symbol                         okei_symbol,
			spcv.qty * CAST(spcvc.consumption AS DECIMAL(17, 3)) qty,
			spcvc.comment                    rm_comment,
			sp.comment                       plan_comment,
			spcv.comment                     cv_comment,
			spcvc.cs_id,
			cs.cs_name,
			spcv.qty                         cv_qty,
			CAST(spcv.dt AS DATETIME)        spcv_dt,
			sp.plan_year,
			sp.plan_month,
			oa_res.supplier_name,
			oa_res.rmo_id,
			oa_res.rmodr_id,
			oa_sr.qty qty_res,
			spcv.sew_office_id,
			os.office_name sew_office_name
	FROM	Planing.SketchPlan sp   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = sp.sketch_id   
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
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = spcvc.rmt_id   
			INNER JOIN	Material.ClothColor cc
				ON	cc.color_id = spcvc.color_id   
			INNER JOIN	Qualifiers.OKEI o
				ON	o.okei_id = spcvc.okei_id   
			INNER JOIN	Material.Completing c
				ON	c.completing_id = spcvc.completing_id   
			INNER JOIN	Planing.CompletingStatus cs
				ON	cs.cs_id = spcvc.cs_id   
			LEFT JOIN Settings.OfficeSetting os
				ON os.office_id = spcv.sew_office_id 
			OUTER APPLY (
			      	SELECT	TOP(1) 
			      	      	sup.supplier_name supplier_name,
			      			rmodfr.rmo_id rmo_id,
			      			rmt2.rmt_id,
			      			rmt2.rmt_name,
			      			cc2.color_name,
			      			cc2.color_id,
			      			rmodfr.qty,
			      			rmodfr.rmodr_id
			      	FROM	Suppliers.RawMaterialStockReserv rmsr   
			      			INNER JOIN	Suppliers.RawMaterialStock rms
			      				ON	rms.rms_id = rmsr.rms_id   
			      			INNER JOIN	Material.RawMaterialType rmt2
			      				ON	rmt2.rmt_id = rms.rmt_id   
			      			INNER JOIN	Material.ClothColor cc2
			      				ON	cc2.color_id = rms.color_id   
			      			INNER JOIN	Suppliers.RawMaterialOrderDetailFromReserv rmodfr
			      				ON	rmodfr.rmsr_id = rmsr.rmsr_id
			      				AND	rmodfr.rmods_id != @rmod_status_deleted   
			      			INNER JOIN	Suppliers.RawMaterialOrder rmo
			      				ON	rmo.rmo_id = rmodfr.rmo_id   
			      			INNER JOIN	Suppliers.Supplier sup
			      				ON	sup.supplier_id = rmo.supplier_id
			      	WHERE	rmsr.spcvc_id = spcvc.spcvc_id
			      	ORDER BY
			      		rmo.rmo_id DESC
			      )                          oa_res
				OUTER APPLY (
			      		SELECT	SUM(smr.quantity) qty
			      		FROM	Warehouse.SHKRawMaterialReserv smr
			      		WHERE	smr.spcvc_id = spcvc.spcvc_id
					  ) oa_sr
	WHERE	sp.ps_id IN (@status_processed_bayer)
			AND	spcv.is_deleted = 0
			AND	(@color_id IS NULL OR spcvc.color_id = @color_id)
			AND	(@rmt_id IS NULL OR spcvc.rmt_id = @rmt_id)
			AND	(@brand_id IS NULL OR s.brand_id = @brand_id)
			AND	(@ct_id IS NULL OR s.ct_id = @ct_id)
			AND	(@plan_year IS NULL OR sp.plan_year = @plan_year)
			AND	(@plan_month IS NULL OR sp.plan_month = @plan_month)
			AND (@spcvc_state_id IS NULL OR spcvc.cs_id = @spcvc_state_id)
	ORDER BY
		sp.dt DESC,
		sp.sp_id,
		spcv.spcv_id,
		spcvc.completing_id,
		spcvc.completing_number
