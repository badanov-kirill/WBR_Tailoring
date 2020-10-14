CREATE PROCEDURE [Synchro].[DownloadUPD_Doc_Get]
	@start_dt DATE = NULL,
	@finish_dt DATE = NULL,
	@supplier_id INT = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	dud.dud_id,
			dud.esf_id,
			dudt.upd_type,
			dud.edo_doc_num,
			CAST(dud.edo_doc_dt AS DATETIME) edo_doc_dt,
			dud.supplier_id,
			s.supplier_name,
			dud.suppliercontract_id,
			sc.suppliercontract_name,
			CAST(dud.edo_sign_date AS DATETIME) edo_sign_date,
			CAST(dud.edo_revoke_date AS DATETIME) edo_revoke_date,
			v.sum_amount
	FROM	Synchro.DownloadUPD_Doc dud   
			LEFT JOIN	Synchro.DownloadUPD_DocType dudt
				ON	dudt.dudt_id = dud.dudt_id   
			LEFT JOIN	Suppliers.Supplier s
				ON	s.supplier_id = dud.supplier_id   
			LEFT JOIN	Suppliers.SupplierContract sc
				ON	sc.suppliercontract_erp_id = dud.suppliercontract_id   
			LEFT JOIN	(SELECT	dudd.dud_id,
			    	    	 		SUM(dudd.edo_amount_with_nds) sum_amount
			    	    	 FROM	Synchro.DownloadUPD_DocDetail dudd
			    	    	 GROUP BY
			    	    	 	dudd.dud_id)v
				ON	v.dud_id = dud.dud_id
	WHERE	dud.dt_proc IS NULL
			AND	(@start_dt IS NULL OR dud.edo_doc_dt >= @start_dt)
			AND	(@finish_dt IS NULL OR dud.edo_doc_dt <= @finish_dt)
			AND	(@supplier_id IS NULL OR dud.supplier_id = @supplier_id)
	ORDER BY
		dud.dud_id