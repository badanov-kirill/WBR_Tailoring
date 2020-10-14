CREATE PROCEDURE [Material].[RawMaterialIncomeRelation_GetBySPCVC]
	@spcvc_id INT,
	@rmt_id INT = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	
	DECLARE @color_id INT
	DECLARE @supplier_id INT
	DECLARE @order_dt DATETIME2(0)
	
	SELECT	TOP(1) @supplier_id = sc.supplier_id,
			@rmt_id       = ISNULL(@rmt_id, rms.rmt_id),
			@color_id     = rms.color_id,
			@order_dt     = DATEADD(day, -7, rmo.create_dt)
	FROM	Planing.SketchPlanColorVariantCompleting spcvc   
			INNER JOIN	Suppliers.RawMaterialStockReserv rmsr
				ON	rmsr.spcvc_id = spcvc.spcvc_id   
			INNER JOIN	Suppliers.RawMaterialStock rms
				ON	rms.rms_id = rmsr.rms_id   
			INNER JOIN	Suppliers.RawMaterialOrderDetailFromReserv rmodfr
				ON	rmodfr.rmsr_id = rmsr.rmsr_id
				AND	rmodfr.rmods_id != 2   
			INNER JOIN	Suppliers.RawMaterialOrder rmo
				ON	rmo.rmo_id = rmodfr.rmo_id   
			INNER JOIN	Suppliers.SupplierContract sc
				ON	sc.suppliercontract_id = rmo.suppliercontract_id
	WHERE	spcvc.spcvc_id = @spcvc_id
	ORDER BY
		rmo.rmo_id DESC
	
	SELECT	rmid.doc_id,
			CAST(rmi.supply_dt AS DATETIME) supply_dt,
			rmid.shkrm_id,
			rmid.rmid_id,
			a.art_name,
			cc.color_name,
			rmid.stor_unit_residues_qty,
			rmid.stor_unit_residues_qty -(ISNULL(oa_orrd.qty, 0) + ISNULL(oa_ord.qty, 0)) free_qty,
			smai.stor_unit_residues_qty - ISNULL(oa_res.res_qty, 0) fact_free_qty,
			o.symbol     okei_symbol,
			o.okei_id,
			rmid.amount,
			rmid.frame_width,
			CAST(CAST(rmi.rv AS BIGINT) AS VARCHAR(20)) rv_bigint
	FROM	Material.RawMaterialIncomeDetail rmid   
			INNER JOIN Warehouse.SHKRawMaterialActualInfo smai
				ON smai.shkrm_id = rmid.shkrm_id
			INNER JOIN	Material.Article a
				ON	a.art_id = rmid.art_id   
			INNER JOIN	Material.ClothColor cc
				ON	cc.color_id = rmid.color_id   
			INNER JOIN	Qualifiers.OKEI o
				ON	o.okei_id = rmid.stor_unit_residues_okei_id   
			INNER JOIN	Material.RawMaterialIncome rmi
				ON	rmi.doc_id = rmid.doc_id
				AND	rmi.doc_type_id = rmid.doc_type_id   
			OUTER APPLY (
			      	SELECT	SUM(rmiorrd.quantity) qty
			      	FROM	Material.RawMaterialIncomeOrderReservRelationDetail rmiorrd
			      	WHERE	rmiorrd.rmid_id = rmid.rmid_id
			      			AND	rmiorrd.doc_id = rmid.doc_id
			      			AND	rmiorrd.doc_type_id = rmid.doc_type_id
			      ) oa_orrd
			OUTER APPLY (
	      			SELECT	SUM(rmiord.quantity) qty
	      			FROM	Material.RawMaterialIncomeOrderRelationDetail rmiord
	      			WHERE	rmiord.rmid_id = rmid.rmid_id
	      					AND	rmiord.doc_id = rmid.doc_id
	      					AND	rmiord.doc_type_id = rmid.doc_type_id
				  )              oa_ord
			OUTER APPLY (
			      	SELECT	SUM(smr.quantity) res_qty
			      	FROM	Warehouse.SHKRawMaterialReserv smr
			      	WHERE	smr.shkrm_id = smai.shkrm_id
			      ) oa_res 
	WHERE	rmid.rmt_id = @rmt_id
			AND	rmi.supply_dt > @order_dt
			AND	rmid.is_defected = 0
			AND	rmid.is_deleted = 0
			AND	(ISNULL(oa_orrd.qty, 0) + ISNULL(oa_ord.qty, 0)) * 1.1 < rmid.stor_unit_residues_qty
			AND ISNULL(oa_res.res_qty, 0) * 1.1 < smai.stor_unit_residues_qty
			AND	rmi.rmis_id IN (4, 5, 6, 7)
			AND rmi.supplier_id = @supplier_id
	ORDER BY
		CASE 
		     WHEN rmid.color_id = @color_id THEN 0
		     ELSE 1
		END,
		rmid.stor_unit_residues_qty -(ISNULL(oa_orrd.qty, 0) + ISNULL(oa_ord.qty, 0)) DESC