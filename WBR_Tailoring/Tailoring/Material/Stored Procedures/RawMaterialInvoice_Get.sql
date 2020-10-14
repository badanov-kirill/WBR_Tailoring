CREATE PROCEDURE [Material].[RawMaterialInvoice_Get]
	@supplier_id INT,
	@start_dt DATE,
	@finish_dt DATE
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	rmi.rmi_id,
			rmi.doc_id,
			rmi.invoice_name,
			CAST(rmi.invoice_dt AS DATETIME) invoice_dt,
			rmi.ttn_name,
			CAST(rmi.ttn_dt AS DATETIME)     ttn_dt,
			CAST(rmi.dt AS DATETIME)         dt,
			es.employee_name
	FROM	Material.RawMaterialInvoice rmi   
			LEFT JOIN	Settings.EmployeeSetting es
				ON	es.employee_id = rmi.employee_id   
			INNER JOIN	Material.RawMaterialIncome rmic
				ON	rmic.doc_id = rmi.doc_id
				AND	rmic.doc_type_id = rmi.doc_type_id
	WHERE	rmic.supplier_id = @supplier_id
			AND	rmi.invoice_dt >= @start_dt
			AND	rmi.invoice_dt <= @finish_dt
			AND	rmi.is_deleted = 0