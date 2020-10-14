CREATE PROCEDURE [Material].[RawMaterialIncomeRelation_GetToReservOperation]
	@doc_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	DECLARE @doc_type_id TINYINT = 1
	
	SELECT	rmiorrd.operation_num,
			rmid.frame_width,
			rmid.shkrm_id,
			rmt.rmt_name,
			a.art_name,
			cc.color_name,
			o.fullname                      okei_name,
			rmid.stor_unit_residues_qty     qty,
			rmodfr.rmo_id,
			1                               order_type,
			occ.color_name                  order_color_name,
			ormt.rmt_name                   order_rmt_name,
			rmodfr.qty                      order_qty,
			rmiorrd.quantity                reserv_qty,
			cg.completing_name,
			spcvc.completing_number,
			spcv.spcv_name,
			s.sa,
			an.art_name product_art_name,
			ISNULL(s.imt_name, sj.subject_name) imt_name
	FROM	Material.RawMaterialIncomeDetail rmid   
			INNER JOIN	Material.RawMaterialIncomeOrderReservRelationDetail rmiorrd
				ON	rmiorrd.rmid_id = rmid.rmid_id   
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
			INNER JOIN	Suppliers.RawMaterialOrderDetailFromReserv rmodfr
				ON	rmodfr.rmodr_id = rmiorrd.rmodr_id   
			INNER JOIN	Suppliers.RawMaterialStockReserv rmsr
				ON	rmsr.rmsr_id = rmodfr.rmsr_id   
			INNER JOIN	Suppliers.RawMaterialStock rms
				ON	rms.rms_id = rmsr.rms_id   
			INNER JOIN	Planing.SketchPlanColorVariantCompleting spcvc
				ON	spcvc.spcvc_id = rmsr.spcvc_id   
			INNER JOIN	Material.Completing cg
				ON	cg.completing_id = spcvc.completing_id   
			INNER JOIN	Material.RawMaterialType ormt
				ON	ormt.rmt_id = rms.rmt_id   
			INNER JOIN	Material.ClothColor occ
				ON	occ.color_id = rms.color_id   
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
	WHERE	rmid.doc_id = @doc_id
			AND	rmid.doc_type_id = @doc_type_id
			AND	rmid.is_deleted = 0
			AND	rmid.is_defected = 0
	UNION ALL
	SELECT	rmiord.operation_num,
			rmid.frame_width,
			rmid.shkrm_id,
			rmt.rmt_name,
			a.art_name,
			cc.color_name,
			o.fullname                      okei_name,
			rmid.stor_unit_residues_qty     qty,
			rmod.rmo_id,
			1                               order_type,
			occ.color_name                  order_color_name,
			ormt.rmt_name                   order_rmt_name,
			rmod.qty                        order_qty,
			rmiord.quantity                 reserv_qty,
			NULL                            completing_name,
			NULL                            completing_number,
			NULL                            spcv_name,
			NULL                            sa,
			NULL                            art_name,
			NULL                            imt_name
	FROM	Material.RawMaterialIncomeDetail rmid   
			INNER JOIN	Material.RawMaterialIncomeOrderRelationDetail rmiord
				ON	rmiord.rmid_id = rmid.rmid_id   
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
			INNER JOIN	Suppliers.RawMaterialOrderDetail rmod
				ON	rmod.rmod_id = rmiord.rmod_id   
			INNER JOIN	Material.RawMaterialType ormt
				ON	ormt.rmt_id = rmod.rmt_id   
			INNER JOIN	Material.ClothColor occ
				ON	occ.color_id = rmod.color_id
	WHERE	rmid.doc_id = @doc_id
			AND	rmid.doc_type_id = @doc_type_id
			AND	rmid.is_deleted = 0
			AND	rmid.is_defected = 0
		
		
