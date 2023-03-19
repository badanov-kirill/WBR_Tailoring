CREATE PROCEDURE [Planing].[ModelClothFromBayer]
	@color_id INT = NULL,
	@rmt_id INT = NULL,
	@brand_id INT = NULL,
	@ct_id INT = NULL,
	@plan_year SMALLINT = NULL,
	@plan_month TINYINT = NULL,
	@office_id INT = NULL,
	@qp_id INT = NULL,
	@ps_id TINYINT = NULL,
	@is_work BIT = NULL,
	@frame_width SMALLINT = NULL,
	@rmt_id2 INT = NULL,
	@cs_id TINYINT = NULL,
	@for_pre_plan BIT = NULL,
	@model_year SMALLINT = NULL,
	@season_local_id INT = NULL,
	@supplier_id INT = NULL,
	@fabricator_id INT = NULL,
	@is_preorder BIT = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	DECLARE @status_bayer TINYINT = 5
	DECLARE @status_bayer_repeat TINYINT = 7
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
			rmt.rmt_name,
			rmt.rmt_id,
			cc.color_name,
			cc.color_id,
			ISNULL(spcvc.frame_width, 0)     frame_width,
			o.symbol                         okei_symbol,
			spcv.qty * CAST(spcvc.consumption AS DECIMAL(17, 3)) qty,
			ISNULL(spcvc.comment, '') + ISNULL(' | ' + oa_c.x, '')                   rm_comment,
			sp.comment                       plan_comment,
			spcv.comment                     cv_comment,
			oa_res.qty_reserv,
			oa_res_s.qty qty_reserv_shk,
			spcvc.cs_id,
			cs.cs_name,
			spcv.qty                         cv_qty,
			CAST(spcv.dt AS DATETIME)        spcv_dt,
			sp.plan_year,
			sp.plan_month,
			ISNULL(oa_res.supplier_name, sup.supplier_name) supplier_name,
			oa_res.rmo_id,
			spcv.sew_office_id,
			os.office_name sew_office_name,
			f.fabricator_name sew_fabricator_name,
			sp.sew_fabricator_id,
			sp.qp_id,
			qp.qp_name,
			CAST(sp.plan_sew_dt AS DATETIME) plan_sew_dt,
			CASE 
			     WHEN sp.spp_id IS NULL THEN 0
			     ELSE 1
			END for_pre_plan,
			CAST(s.construction_close_dt AS DATETIME) construction_close_dt,
			CAST(sp.to_purchase_dt AS DATETIME) to_purchase_dt,
			oa_p.x office_pattern
	FROM	Planing.SketchPlan sp   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = sp.sketch_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id   
			INNER JOIN	Products.[Subject] sj
				ON	sj.subject_id = s.subject_id   
			INNER JOIN	Products.Brand b
				ON	b.brand_id = s.brand_id   
			INNER JOIN	Planing.SketchPlanColorVariant spcv--
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
			LEFT JOIN Settings.OfficeSetting os
				ON os.office_id = spcv.sew_office_id 
			INNER JOIN Products.QueuePriority qp
				ON qp.qp_id = sp.qp_id 
			LEFT JOIN Suppliers.Supplier sup 
				ON sup.supplier_id = spcvc.supplier_id
			LEFT JOIN Settings.Fabricators f 
				ON f.fabricator_id = sp.sew_fabricator_id
			OUTER APPLY (
			      	SELECT	SUM(CASE WHEN rmodfr.rmodr_id IS NULL AND	rms.end_dt_offer > @dt THEN rmsr.qty ELSE 0 END) qty_reserv,
			      			MAX(CASE WHEN rmodfr.rmods_id = @rmod_status_deleted THEN NULL ELSE sup.supplier_name END) supplier_name,
			      			MAX(CASE WHEN rmodfr.rmods_id = @rmod_status_deleted THEN NULL ELSE rmodfr.rmo_id END) rmo_id
			      	FROM	Suppliers.RawMaterialStockReserv rmsr   
			      			INNER JOIN	Suppliers.RawMaterialStock rms
			      				ON	rms.rms_id = rmsr.rms_id   
			      			INNER JOIN	Suppliers.Supplier sup
			      				ON	sup.supplier_id = rms.supplier_id   
			      			LEFT JOIN	Suppliers.RawMaterialOrderDetailFromReserv rmodfr
			      				ON	rmodfr.rmsr_id = rmsr.rmsr_id
			      	WHERE	rmsr.spcvc_id = spcvc.spcvc_id			      			
			      )                          oa_res
			OUTER APPLY (
					SELECT spcvcc.comment + ' | '
					FROM Planing.SketchPlanColorVariantCompletingComment spcvcc
					WHERE spcvcc.spcvc_id = spcvc.spcvc_id
					FOR XML PATH('')
			) oa_c(x)
			OUTER APPLY (
			      	SELECT	SUM(smr.quantity) qty
			      	FROM	Warehouse.SHKRawMaterialReserv smr
			      	WHERE	smr.spcvc_id = spcvc.spcvc_id
			      ) oa_res_s
			OUTER APPLY (
			      	SELECT	os.office_name + '; '
			      	FROM	Products.SketchBranchOfficePattern sbop   
			      			INNER JOIN	Settings.OfficeSetting os
			      				ON	os.office_id = sbop.office_id
			      	WHERE	sbop.sketch_id = s.sketch_id
			      	FOR XML	PATH('')
			      ) oa_p(x)
	WHERE	sp.ps_id IN (@status_bayer, @status_bayer_repeat)
			AND	spcv.is_deleted = 0
			AND	(@color_id IS NULL OR spcvc.color_id = @color_id)
			AND	(@rmt_id IS NULL OR spcvc.rmt_id = @rmt_id)
			AND	(@brand_id IS NULL OR s.brand_id = @brand_id)
			AND	(@ct_id IS NULL OR s.ct_id = @ct_id)
			AND	(@plan_year IS NULL OR sp.plan_year = @plan_year)
			AND	(@plan_month IS NULL OR sp.plan_month = @plan_month)
			AND (@office_id IS NULL OR sp.sew_office_id = @office_id)
			AND (@qp_id IS NULL OR sp.qp_id = @qp_id)
			AND (@ps_id IS NULL OR sp.ps_id = @ps_id)
			AND (@frame_width IS NULL OR spcvc.frame_width = @frame_width)
			AND (@cs_id IS NULL OR spcvc.cs_id = @cs_id)
			AND (@for_pre_plan IS NULL OR (@for_pre_plan = 0 AND sp.spp_id IS NULL) OR (@for_pre_plan = 1 AND sp.spp_id IS NOT NULL))
			AND (@model_year IS NULL OR sp.season_model_year = @model_year)
			AND	(@season_local_id IS NULL OR sp.season_local_id = @season_local_id)
			AND (@supplier_id IS NULL OR spcvc.supplier_id = @supplier_id)
			AND (@fabricator_id IS NULL OR sp.sew_fabricator_id = @fabricator_id)
			AND (@is_preorder IS NULL OR sp.is_preorder = @is_preorder)
			AND (
			    	@is_work IS NULL
			    	OR (@is_work = 1 AND EXISTS (
			    	   	SELECT	1
			    	   	FROM	Planing.SketchPlanColorVariantCompleting spcvc2   
			    	   			INNER JOIN	Planing.SketchPlanColorVariant spcv2
			    	   				ON	spcv2.spcv_id = spcvc2.spcv_id
			    	   	WHERE	spcv2.sp_id = sp.sp_id
			    	   			AND spcv2.is_deleted = 0
			    	   			AND spcvc2.consumption > 0
			    	   	GROUP BY
			    	   		spcv2.sp_id
			    	   	HAVING
			    	   		MAX(spcvc2.cs_id) IN (2, 3)
			    	   	AND MIN(spcvc2.cs_id) = 1
			    	   ))
			    	   OR (@is_work = 0 AND NOT EXISTS (
			    	   	SELECT	1
			    	   	FROM	Planing.SketchPlanColorVariantCompleting spcvc2   
			    	   			INNER JOIN	Planing.SketchPlanColorVariant spcv2
			    	   				ON	spcv2.spcv_id = spcvc2.spcv_id
			    	   	WHERE	spcv2.sp_id = sp.sp_id
			    	   			AND spcvc2.cs_id IN (2,3)
			    	   			AND spcv2.is_deleted = 0
			    	   			AND spcvc2.consumption > 0
			    	   ))
			)
			AND (
			    	@rmt_id2 IS NULL
			    	OR EXISTS (
			    	   	SELECT	1
			    	   	FROM	Planing.SketchPlanColorVariantCompleting spcvc2
			    	   	WHERE	spcvc2.spcv_id = spcv.spcv_id
			    	   			AND	spcvc2.rmt_id = @rmt_id2
			    	   )
			    )
	ORDER BY
		sp.qp_id,
		sp.dt DESC,
		sp.sp_id,
		spcv.spcv_id,
		spcvc.completing_id,
		spcvc.completing_number
