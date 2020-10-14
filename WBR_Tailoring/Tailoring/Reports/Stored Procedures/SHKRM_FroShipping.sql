CREATE PROCEDURE [Reports].[SHKRM_FroShipping]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	DECLARE @cv_status_placing TINYINT = 12 --Назначен в цех
	
	
	SELECT	v.shkrm_id,
			rmt.rmt_name,
			smsd.state_name,
			v.place_name,
			v.office_name,
			oap.x                            sketch_info,
			ossh.office_name                 shipping_office,
			CAST(ps.plan_dt AS DATETIME)     plan_shipping_dt,
			CASE 
			     WHEN psd.ttnd_id IS NULL THEN 0
			     ELSE 1
			END                              is_ttn,
			cc.color_name,
			a.art_name,
			smai.frame_width,
			smai.stor_unit_residues_qty      qty,
			o.symbol                         okei_symbol
	FROM	(SELECT	smr.shkrm_id,
	    	 		spl.place_name,
	    	 		os.office_name
	    	 FROM	Warehouse.SHKRawMaterialReserv smr   
	    	 		INNER JOIN	Warehouse.SHKRawMaterialOnPlace smop   
	    	 		INNER JOIN	Warehouse.StoragePlace spl
	    	 			ON	spl.place_id = smop.place_id   
	    	 		INNER JOIN	Warehouse.ZoneOfResponse zor   
	    	 		INNER JOIN	Settings.OfficeSetting os
	    	 			ON	os.office_id = zor.office_id
	    	 			ON	zor.zor_id = spl.zor_id
	    	 			ON	smop.shkrm_id = smr.shkrm_id
	    	 WHERE	EXISTS (
	    	      		SELECT	1
	    	      		FROM	Planing.SketchPlanColorVariant spcv   
	    	      				INNER JOIN	Planing.SketchPlanColorVariantCompleting spcvc
	    	      					ON	spcvc.spcv_id = spcv.spcv_id
	    	      		WHERE	spcvc.spcvc_id = smr.spcvc_id
	    	      				AND	spcv.cvs_id = @cv_status_placing
	    	      				AND	spcv.sew_office_id != zor.office_id
	    	      	)
	    	 GROUP BY
	    	 	smr.shkrm_id,
	    	 	spl.place_name,
	    	 	os.office_name)v(shkrm_id,
			place_name,
			office_name)   
			INNER JOIN	Warehouse.SHKRawMaterialActualInfo smai
				ON	smai.shkrm_id = v.shkrm_id   
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = smai.rmt_id   
			INNER JOIN	Material.ClothColor cc
				ON	cc.color_id = smai.color_id   
			INNER JOIN	Material.Article a
				ON	a.art_id = smai.art_id   
			INNER JOIN	Qualifiers.OKEI o
				ON	o.okei_id = smai.stor_unit_residues_okei_id   
			LEFT JOIN	Planing.PlanShippingDetail psd   
			INNER JOIN	Planing.PlanShipping ps   
			INNER JOIN	Settings.OfficeSetting ossh
				ON	ossh.office_id = ps.dst_office_id
				ON	ps.ps_id = psd.ps_id
				ON	psd.shkrm_id = v.shkrm_id
				AND	psd.shipping_dt IS NULL   
			INNER JOIN	Warehouse.SHKRawMaterialState sms   
			INNER JOIN	Warehouse.SHKRawMaterialStateDict smsd
				ON	smsd.state_id = sms.state_id
				ON	sms.shkrm_id = v.shkrm_id   
			OUTER APPLY (
			      	SELECT	vv.art_name + '|' + FORMAT(vv.qty, '0.0') + ' (' + vv.office_name + '); '
			      	FROM	(SELECT	an2.art_name,
			      	    	 		os.office_name,
			      	    	 		SUM(smr2.quantity) qty
			      	    	 FROM	Warehouse.SHKRawMaterialReserv smr2   
			      	    	 		INNER JOIN	Planing.SketchPlanColorVariantCompleting spcvc2
			      	    	 			ON	spcvc2.spcvc_id = smr2.spcvc_id   
			      	    	 		INNER JOIN	Planing.SketchPlanColorVariant spcv2
			      	    	 			ON	spcv2.spcv_id = spcvc2.spcv_id   
			      	    	 		INNER JOIN	Planing.SketchPlan sp2
			      	    	 			ON	sp2.sp_id = spcv2.sp_id   
			      	    	 		INNER JOIN	Products.Sketch s2
			      	    	 			ON	s2.sketch_id = sp2.sketch_id   
			      	    	 		INNER JOIN	Products.ArtName an2
			      	    	 			ON	an2.art_name_id = s2.art_name_id   
			      	    	 		INNER JOIN	Settings.OfficeSetting os
			      	    	 			ON	os.office_id = spcv2.sew_office_id
			      	    	 WHERE	smr2.shkrm_id = v.shkrm_id
			      	    	 		AND	spcv2.cvs_id = @cv_status_placing
			      	    	 GROUP BY
			      	    	 	an2.art_name,
			      	    	 	os.office_name)vv
			      	FOR XML	PATH('')
			      ) oap(x)