CREATE PROCEDURE [Planing].[SketchPlanColorVariantPlacing_GetShk]
	@src_office_id INT,
	@dst_office_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	DECLARE @cv_status_placing TINYINT = 12 --Назначен в цех
	DECLARE @cv_status_pre_placing TINYINT = 17 --Подготовлен к запуску
	DECLARE @shkrm_state_expanded TINYINT = 3
	
	SELECT	v.shkrm_id,
			v.place_name,
			rmt.rmt_name,
			a.art_name,
			cc.color_name,
			smai.frame_width,
			smai.stor_unit_residues_qty     qty,
			o.symbol                        okei_symbol,
			CAST(smai.gross_mass AS DECIMAL(9, 1)) / 1000 gross_mass,
			oap.x                           sketch_info
	FROM	(SELECT	smr.shkrm_id,
	    	 		spl.place_name
	    	 FROM	Warehouse.SHKRawMaterialReserv smr   
	    	 		INNER JOIN	Warehouse.SHKRawMaterialOnPlace smop   
	    	 		INNER JOIN	Warehouse.StoragePlace spl
	    	 			ON	spl.place_id = smop.place_id   
	    	 		INNER JOIN	Warehouse.ZoneOfResponse zor
	    	 			ON	zor.zor_id = spl.zor_id
	    	 			ON	smop.shkrm_id = smr.shkrm_id
	    	 		INNER JOIN Warehouse.SHKRawMaterialState sms
	    	 			ON sms.shkrm_id = smr.shkrm_id
	    	 WHERE	EXISTS (
	    	      		SELECT	1
	    	      		FROM	Planing.SketchPlanColorVariant spcv   
	    	      				INNER JOIN	Planing.SketchPlanColorVariantCompleting spcvc
	    	      					ON	spcvc.spcv_id = spcv.spcv_id
	    	      		WHERE	spcvc.spcvc_id = smr.spcvc_id
	    	      				AND	spcv.cvs_id IN (@cv_status_placing, @cv_status_pre_placing)
	    	      				AND	spcv.sew_office_id = @dst_office_id
	    	      	)
	    	 		AND	NOT EXISTS (
	    	 		   		SELECT	1
	    	 		   		FROM	Planing.PlanShippingDetail psd
	    	 		   		WHERE	psd.shkrm_id = smr.shkrm_id
	    	 		   				AND	psd.shipping_dt IS NULL
	    	 		   	)
	    	 		AND	zor.office_id = @src_office_id
	    	 		AND sms.state_id = @shkrm_state_expanded
	    	 GROUP BY
	    	 	smr.shkrm_id,
	    	 	spl.place_name)v(shkrm_id,
			place_name)   
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
			OUTER APPLY (
			      	SELECT	an2.art_name + '|' + FORMAT(smr2.quantity, '0.0') + '(' + ISNULL(pa2.sa + pan2.sa, 'не связан') + '); '
			      	FROM	Warehouse.SHKRawMaterialReserv smr2   
			      			INNER JOIN	Planing.SketchPlanColorVariantCompleting spcvc2
			      				ON	spcvc2.spcvc_id = smr2.spcvc_id   
			      			INNER JOIN	Planing.SketchPlanColorVariant spcv2
			      				ON	spcv2.spcv_id = spcvc2.spcv_id   
			      			LEFT JOIN	Products.ProdArticleNomenclature pan2   
			      			INNER JOIN	Products.ProdArticle pa2
			      				ON	pa2.pa_id = pan2.pa_id
			      				ON	pan2.pan_id = spcv2.pan_id   
			      			INNER JOIN	Planing.SketchPlan sp2
			      				ON	sp2.sp_id = spcv2.sp_id   
			      			INNER JOIN	Products.Sketch s2
			      				ON	s2.sketch_id = sp2.sketch_id   
			      			INNER JOIN	Products.ArtName an2
			      				ON	an2.art_name_id = s2.art_name_id
			      	WHERE	smr2.shkrm_id = v.shkrm_id
			      	FOR XML	PATH('')
			      ) oap(x)