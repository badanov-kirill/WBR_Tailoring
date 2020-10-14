CREATE PROCEDURE [Suppliers].[RawMaterialRefund_GetDetail]
	@rmr_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	rmr.supplier_id,
			rmr.suppliercontract_id,
			rmr.rmrs_id,
			CAST(rmr.sending_dt AS DATETIME) sending_dt,
			rmr.is_deleted,
			CAST(rmr.rv AS BIGINT)       rv_bigint,
			CAST(rmr.create_dt AS DATETIME) create_dt,
			rmr.create_employee_id,
			CAST(rmr.dt AS DATETIME)     dt,
			rmr.employee_id,
			rmr.comment,
			s.supplier_name,
			sc.suppliercontract_name,
			rmrs.rmrs_name
	FROM	Suppliers.RawMaterialRefund rmr   
			INNER JOIN	Suppliers.Supplier s
				ON	s.supplier_id = rmr.supplier_id   
			INNER JOIN	Suppliers.SupplierContract sc
				ON	sc.suppliercontract_id = rmr.suppliercontract_id   
			INNER JOIN	Suppliers.RawMaterialRefundStatus rmrs
				ON	rmrs.rmrs_id = rmr.rmrs_id
	WHERE	rmr.rmr_id = @rmr_id
	
	SELECT	rmrsd.rmrsd_id,
			rmrsd.rmid_id,
			rmrsd.shkrm_id,
			rmrsd.rmt_id,
			rmrsd.art_id,
			rmrsd.color_id,
			rmrsd.qty,
			rmrsd.okei_id,
			rmrsd.stor_unit_residues_okei_id,
			rmrsd.stor_unit_residues_qty,
			rmrsd.frame_width,
			CAST(rmrsd.dt AS DATETIME)     dt,
			rmrsd.employee_id,
			rmt.rmt_name,
			a.art_name,
			cc.color_name,
			o.fullname                     okei_name,
			smdd.descr,
			rmid.doc_id
	FROM	Suppliers.RawMaterialRefundShkDetail rmrsd   
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = rmrsd.rmt_id   
			INNER JOIN	Material.ClothColor cc
				ON	cc.color_id = rmrsd.color_id   
			INNER JOIN	Material.Article a
				ON	a.art_id = rmrsd.art_id   
			INNER JOIN	Qualifiers.OKEI o
				ON	o.okei_id = rmrsd.okei_id   
			LEFT JOIN	Warehouse.SHKRawMaterialDefectDescr smdd
				ON	smdd.shkrm_id = rmrsd.shkrm_id   
			LEFT JOIN	Material.RawMaterialIncomeDetail rmid
				ON	rmid.rmid_id = rmrsd.rmid_id
	WHERE	rmrsd.rmr_id = @rmr_id
			AND	rmrsd.is_deleted = 0
	
	SELECT	rmrsd.rmrsd_id,
			rmrsd.shks_id,
			rmrsd.qty,
			rmrsd.okei_id,
			CAST(rmrsd.dt AS DATETIME) dt,
			rmrsd.employee_id,
			ssu.descript,			
			su.su_name,
			ssu.shksu_id
	FROM	Suppliers.RawMaterialRefundSuspectDetail rmrsd   
			INNER JOIN	Warehouse.SHKSuspectUnit ssu
				ON	ssu.shks_id = rmrsd.shks_id   
			INNER JOIN	Warehouse.SHKSpaceUnit ssu2
				ON	ssu2.shksu_id = ssu.shksu_id   
			INNER JOIN	RefBook.SpaceUnit su
				ON	su.su_id = ssu2.su_id
	WHERE	rmrsd.rmr_id = @rmr_id
			AND	rmrsd.is_deleted = 0
GO	