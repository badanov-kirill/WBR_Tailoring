CREATE PROCEDURE [Material].[RawMaterialInvoiceCorrection_GetList]
	@start_create_dt DATETIME = NULL,
	@finish_create_dt DATETIME = NULL,
	@supplier_id INT = NULL,
	@is_close BIT = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	rmic.rmic_id,
			rmic.rmi_id,
			rmic.base_invoice_name,
			CAST(rmic.base_invoice_dt AS DATETIME) base_invoice_dt,
			rmic.buch_num,
			CAST(rmic.create_dt AS DATETIME) create_dt,
			es.employee_name       create_employee_name,
			escl.employee_name     close_employee_name,
			CAST(rmic.close_dt AS DATETIME) close_dt,
			rmic.comment,
			rmic.amount_invoice,
			rmic.amount_shk,
			s.supplier_name
	FROM	Material.RawMaterialInvoiceCorrection rmic   
			INNER JOIN	Material.RawMaterialInvoice rmi
				ON	rmi.rmi_id = rmic.rmi_id   
			INNER JOIN	Material.RawMaterialIncome rmicom
				ON	rmicom.doc_id = rmi.doc_id
				AND	rmicom.doc_type_id = rmi.doc_type_id   
			INNER JOIN	Suppliers.Supplier s
				ON	s.supplier_id = rmicom.supplier_id   
			LEFT JOIN	Settings.EmployeeSetting es
				ON	es.employee_id = rmic.create_employee_id   
			LEFT JOIN	Settings.EmployeeSetting escl
				ON	escl.employee_id = rmic.close_employee_id
	WHERE	(@start_create_dt IS NULL OR rmic.create_dt >= @start_create_dt)
			AND	(@finish_create_dt IS NULL OR rmic.create_dt <= @finish_create_dt)
			AND	(@supplier_id IS NULL OR rmicom.supplier_id = @supplier_id)
			AND	(@is_close IS NULL OR (@is_close = 0 AND rmic.close_dt IS NULL) OR (@is_close = 1 AND rmic.close_dt IS NOT NULL))