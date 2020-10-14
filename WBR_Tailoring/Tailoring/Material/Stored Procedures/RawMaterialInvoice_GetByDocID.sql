CREATE PROCEDURE [Material].[RawMaterialInvoice_GetByDocID]
	@doc_id INT
AS
	DECLARE @doc_type_id TINYINT = 1
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	rmi.rmi_id,
			rmi.doc_id,
			rmi.invoice_name,
			CAST(rmi.invoice_dt AS DATETIME) invoice_dt,
			rmi.ttn_name,
			CAST(rmi.ttn_dt AS DATETIME)     ttn_dt,
			CAST(rmi.dt AS DATETIME)         dt,
			es.employee_name,
			rmi.is_deleted
	FROM	Material.RawMaterialInvoice rmi   
			LEFT JOIN	Settings.EmployeeSetting es
				ON	es.employee_id = rmi.employee_id   
			INNER JOIN	Material.RawMaterialIncome rmic
				ON	rmic.doc_id = rmi.doc_id
				AND	rmic.doc_type_id = rmi.doc_type_id
	WHERE	rmi.doc_id = @doc_id
			AND	rmic.doc_type_id = @doc_type_id
			AND (rmi.is_deleted = 0 OR rmi.sync_finance_dt IS NOT NULL)
			AND rmi.is_deleted = 0