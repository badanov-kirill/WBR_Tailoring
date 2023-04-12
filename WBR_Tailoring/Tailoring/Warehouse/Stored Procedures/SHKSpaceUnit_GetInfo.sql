CREATE PROCEDURE [Warehouse].[SHKSpaceUnit_GetInfo]
	@shksu_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	su.shksu_id,
			su.doc_id,
			su.doc_type_id,
			su.su_id,
			su.quantity,
			CAST(di.create_dt AS DATETIME) create_dt,
			CAST(su.close_dt AS DATETIME) close_dt,
			su.close_employee_id,
			CAST(rmi.supply_dt AS DATETIME) supply_dt,
			s.supplier_name,
			di.create_employee_id,
			ISNULL(oa_inv.inv_cnt, 0) inv_cnt,
			rmi.fabricator_id,
			f.fabricator_name
	FROM	Warehouse.SHKSpaceUnit su   
			LEFT JOIN	Material.RawMaterialIncome rmi 
			LEFT JOIN Settings.Fabricators f on f.fabricator_id = rmi.fabricator_id
			INNER JOIN	Suppliers.Supplier s
				ON	s.supplier_id = rmi.supplier_id   
			INNER JOIN	Documents.DocumentID di
				ON	di.doc_id = rmi.doc_id
				AND	di.doc_type_id = rmi.doc_type_id
				ON	rmi.doc_id = su.doc_id
				AND	rmi.doc_type_id = su.doc_type_id   
			OUTER APPLY (
			      	SELECT	COUNT(1) inv_cnt
			      	FROM	Material.RawMaterialInvoice rminv
			      	WHERE	rminv.doc_id = di.doc_id
			      			AND	rminv.doc_type_id = di.doc_type_id
			      ) oa_inv
	WHERE	su.shksu_id = @shksu_id