CREATE PROCEDURE [Material].[RawMaterialIncomeRelation_GetToReserv_v2]
	@doc_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	DECLARE @doc_type_id TINYINT = 1
	DECLARE @rmod_status_deleted TINYINT = 2 -- удален
	
	DECLARE @tab_order TABLE (rmo_id INT)
	DECLARE @tab_order_detail TABLE (rmo_id INT, rmod_id INT, rmt_id INT, color_id INT, okei_id INT, frame_width SMALLINT, qty DECIMAL(9, 3))	
	DECLARE @tab_order_reserv TABLE (rmo_id INT, rmodr_id INT, spcvc_id INT, qty DECIMAL(9, 3), rms_id INT) 
	
	INSERT @tab_order
	  (
	    rmo_id
	  )
	SELECT	rmo.rmo_id
	FROM	Material.RawMaterialIncomeOrder rmo
	WHERE	rmo.doc_id = @doc_id
			AND	rmo.doc_type_id = @doc_type_id
	
	INSERT @tab_order_detail
	  (
	    rmo_id,
	    rmod_id,
	    rmt_id,
	    color_id,
	    okei_id,
	    frame_width,
	    qty
	  )
	SELECT	tab_o.rmo_id,
			rmod.rmod_id,
			rmod.rmt_id,
			rmod.color_id,
			rmod.okei_id,
			rmod.frame_width,
			rmod.qty
	FROM	@tab_order tab_o   
			INNER JOIN	Suppliers.RawMaterialOrderDetail rmod
				ON	rmod.rmo_id = tab_o.rmo_id
	WHERE rmod.rmods_id != @rmod_status_deleted
	
	INSERT @tab_order_reserv
	  (
	    rmo_id,
	    rmodr_id,
	    spcvc_id,
	    qty,
	    rms_id
	  )
	SELECT	tab_o.rmo_id,
			rmodr.rmodr_id,
			rmsr.spcvc_id,
			rmodr.qty,
			rmsr.rms_id
	FROM	@tab_order tab_o   
			INNER JOIN	Suppliers.RawMaterialOrderDetailFromReserv rmodr
				ON	rmodr.rmo_id = tab_o.rmo_id   
			INNER JOIN	Suppliers.RawMaterialStockReserv rmsr
				ON	rmsr.rmsr_id = rmodr.rmsr_id
	WHERE rmodr.rmods_id != @rmod_status_deleted
	
	SELECT	rmid.rmid_id,
			rmid.frame_width,
			rmid.shkrm_id,
			rmid.rmt_id,
			rmt.rmt_name,
			rmid.art_id,
			a.art_name,
			rmid.color_id,
			cc.color_name,
			rmid.su_id,
			su.su_name,
			rmid.okei_id,
			o.fullname     okei_name,
			rmid.stor_unit_residues_qty qty,
			rmid.amount,
			ISNULL(oa_smr.quantity, 0) + ISNULL(oa.qty_reserv, 0) qty_reserv,
			smai.shkrm_id actual_shkrm_id,
			oao.x office_reserv
	FROM	Material.RawMaterialIncomeDetail rmid   
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = rmid.rmt_id   
			INNER JOIN	RefBook.SpaceUnit su
				ON	su.su_id = rmid.su_id   
			INNER JOIN	Material.ClothColor cc
				ON	cc.color_id = rmid.color_id   
			INNER JOIN	Material.Article a
				ON	a.art_id = rmid.art_id   
			INNER JOIN	Qualifiers.OKEI o
				ON	o.okei_id = rmid.stor_unit_residues_okei_id
			LEFT JOIN Warehouse.SHKRawMaterialActualInfo smai
				ON rmid.shkrm_id = smai.shkrm_id AND rmid.doc_id = smai.doc_id AND rmid.doc_type_id = smai.doc_type_id   
			OUTER APPLY (
			      	SELECT	SUM(smr.quantity) quantity
			      	FROM	Warehouse.SHKRawMaterialReserv smr
			      	WHERE	smr.shkrm_id = rmid.shkrm_id
			      ) oa_smr   
			OUTER APPLY (
			      	SELECT	SUM(rmiord.quantity) qty_reserv
			      	FROM	Material.RawMaterialIncomeOrderRelationDetail rmiord
			      	WHERE	rmiord.rmid_id = rmid.rmid_id
			      )        oa
			OUTER APPLY (
					SELECT	v.office_name + '(' + FORMAT(v.qty, '0.0') + '); '
					FROM	(SELECT	os2.office_name, SUM(smr2.quantity) qty
					    	 FROM	Warehouse.SHKRawMaterialReserv smr2   
					    	 		INNER JOIN	Planing.SketchPlanColorVariantCompleting spcvc2
					    	 			ON	spcvc2.spcvc_id = smr2.spcvc_id   
					    	 		INNER JOIN	Planing.SketchPlanColorVariant spcv2
					    	 			ON	spcv2.spcv_id = spcvc2.spcv_id   
					    	 		INNER JOIN	Settings.OfficeSetting os2
					    	 			ON	os2.office_id = spcv2.sew_office_id
					    	 WHERE	smr2.shkrm_id = rmid.shkrm_id
					    	 GROUP BY os2.office_name
					)v(office_name, qty)
					FOR XML	PATH('')			      	
			) oao(x)
	WHERE	rmid.doc_id = @doc_id
			AND	rmid.doc_type_id = @doc_type_id
			AND	rmid.is_deleted = 0
			AND	rmid.is_defected = 0
	ORDER BY
		rmid.shkrm_id	
	
	SELECT	tod.rmo_id,
			tod.rmt_id,
			tod.color_id,
			tod.okei_id,
			tod.frame_width,
			tod.qty,
			cc.color_name,
			o.fullname                   okei_name,
			rmt.rmt_name,
			tod.rmod_id,
			ISNULL(oa.qty_reserv, 0)     qty_reserv
	FROM	@tab_order_detail tod   
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = tod.rmt_id   
			INNER JOIN	Material.ClothColor cc
				ON	cc.color_id = tod.color_id   
			INNER JOIN	Qualifiers.OKEI o
				ON	o.okei_id = tod.okei_id   
			OUTER APPLY (
			      	SELECT	SUM(rmiord.quantity) qty_reserv
			      	FROM	Material.RawMaterialIncomeOrderRelationDetail rmiord
			      	WHERE	rmiord.rmod_id = tod.rmod_id
			      )                      oa
	
	SELECT	tor.rmo_id,
			tor.rmodr_id,
			tor.spcvc_id,
			tor.qty,
			spcvc.rmt_id,
			spcvc.color_id,
			spcvc.frame_width,
			spcvc.okei_id,
			cc.color_name + ' / ' + ISNULL(os.office_name, 'без офиса') color_name,
			o.fullname                  okei_name,
			rmt.rmt_name,
			ISNULL(oa_smr.quantity, 0)     qty_reserv,
			cg.completing_name,
			spcvc.completing_number,
			spcv.spcv_name,
			s.sa,
			an.art_name,
			ISNULL(s.imt_name, sj.subject_name) imt_name,
			ISNULL(os.office_name, 'без офиса') office_name
	FROM	@tab_order_reserv tor   
			INNER JOIN	Planing.SketchPlanColorVariantCompleting spcvc
				ON	spcvc.spcvc_id = tor.spcvc_id   
			INNER JOIN	Material.Completing cg
				ON	cg.completing_id = spcvc.completing_id   
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = spcvc.rmt_id   			  
			INNER JOIN	Qualifiers.OKEI o
				ON	o.okei_id = spcvc.okei_id    
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
				ON	rms.rms_id = tor.rms_id
			INNER JOIN	Material.ClothColor cc
				ON	cc.color_id = rms.color_id
			LEFT JOIN Settings.OfficeSetting os
				ON	os.office_id = spcv.sew_office_id 
			OUTER APPLY (
			      	SELECT	SUM(smr.quantity) quantity
			      	FROM	Warehouse.SHKRawMaterialReserv smr
			      	WHERE	smr.spcvc_id = tor.spcvc_id
			      ) oa_smr
	
	SELECT	rmiord.rmid_id,
			rmiord.rmod_id,
			rmiord.okei_id,
			rmiord.quantity,
			rmiord.operation_num
	FROM	@tab_order_detail tod   
			INNER JOIN	Material.RawMaterialIncomeOrderRelationDetail rmiord
				ON	rmiord.rmod_id = tod.rmod_id
	WHERE	rmiord.doc_id = @doc_id
			AND	rmiord.doc_type_id = @doc_type_id			
	
	SELECT	rmiorrd.rmid_id,
			rmiorrd.rmodr_id,
			rmiorrd.spcvc_id,
			rmiorrd.okei_id,
			rmiorrd.quantity,
			rmiorrd.operation_num
	FROM	@tab_order_reserv tor   
			INNER JOIN	Material.RawMaterialIncomeOrderReservRelationDetail rmiorrd
				ON	rmiorrd.rmodr_id = tor.rmodr_id
	WHERE	rmiorrd.doc_id = @doc_id
			AND	rmiorrd.doc_type_id = @doc_type_id
			
	SELECT	CAST(CAST(rmi.rv AS BIGINT) AS VARCHAR(20)) rv_bigint
	FROM	Material.RawMaterialIncome rmi
	WHERE	rmi.doc_id = @doc_id
			AND	@doc_type_id = @doc_type_id
			
GO