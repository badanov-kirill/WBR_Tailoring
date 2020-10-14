CREATE PROCEDURE [Material].[RawMaterialIncome_GetList]
	@top_n INT = 500,
	@supplier_id INT = NULL,
	@start_create_dt DATETIME2(0) = NULL,
	@finish_create_dt DATETIME2(0) = NULL,
	@supply_dt DATE = NULL,
	@goods_dt DATE = NULL,
	@rmis_id INT = NULL,
	@suppliercontract_erp_id INT = NULL,
	@is_ots BIT = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	DECLARE @doc_type_id TINYINT = 1
	
	SELECT	TOP(@top_n) 
	      	rmi.doc_id,
			rmis.rmis_name,
			CAST(di.create_dt AS DATETIME) create_dt,
			s.supplier_id,
			s.supplier_name,
			CAST(rmi.goods_dt AS DATETIME) goods_dt,
			rmi.plan_sum,
			CAST(rmi.supply_dt AS DATETIME) supply_dt,
			sc.suppliercontract_code,
			sc.suppliercontract_name,
			CAST(CAST(rmi.rv AS BIGINT) AS VARCHAR(20)) rv_bigint,
			rmi.payment_comment,
			rmi.comment,
			oa_i.invoice_sum,
			STUFF(oa_inv.x, 1, 3, '')     invoices,
			c.currency_name_shot,
			rmi.ots_id
	FROM	Documents.DocumentID di   
			INNER JOIN	Material.RawMaterialIncome rmi
				ON	di.doc_id = rmi.doc_id
				AND	di.doc_type_id = rmi.doc_type_id   
			INNER JOIN	Material.RawMaterialIncomeStatus rmis
				ON	rmis.rmis_id = rmi.rmis_id   
			INNER JOIN	Suppliers.Supplier s
				ON	s.supplier_id = rmi.supplier_id   
			INNER JOIN	Suppliers.SupplierContract sc
				ON	sc.suppliercontract_id = rmi.suppliercontract_id 
			LEFT JOIN RefBook.Currency c ON c.currency_id = sc.currency_id  
			OUTER APPLY (
			      	SELECT	SUM(rmid.amount_with_nds) invoice_sum
			      	FROM	Material.RawMaterialInvoice rmi2   
			      			INNER JOIN	Material.RawMaterialInvoiceDetail rmid
			      				ON	rmid.rmi_id = rmi2.rmi_id
			      	WHERE	rmi2.doc_id = rmi.doc_id
			      			AND	rmi2.doc_type_id = rmi.doc_type_id
			      			AND	rmi2.is_deleted = 0
			      ) oa_i
			OUTER APPLY (
	      			SELECT	' ; ' + rminv.invoice_name + ' от ' + CAST(rminv.invoice_dt AS VARCHAR(20)) + ''
	      			FROM	Material.RawMaterialInvoice rminv
	      			WHERE	rminv.doc_id = rmi.doc_id
	      					AND	rminv.doc_type_id = rmi.doc_type_id
	      					AND	rminv.is_deleted = 0
	      			FOR XML	PATH('')
				  ) oa_inv(x)
	WHERE	(@supplier_id IS NULL OR @supplier_id = s.supplier_id)
			AND	(@start_create_dt IS NULL OR di.create_dt >= @start_create_dt)
			AND	(@finish_create_dt IS NULL OR di.create_dt <= @finish_create_dt)
			AND	(@supply_dt IS NULL OR rmi.supply_dt = @supply_dt)
			AND	(@goods_dt IS NULL OR rmi.goods_dt = @goods_dt)
			AND	(@rmis_id IS NULL OR rmi.rmis_id = @rmis_id)
			AND	di.doc_type_id = @doc_type_id
			AND rmi.is_deleted = 0
			AND (@suppliercontract_erp_id IS NULL OR sc.suppliercontract_erp_id = @suppliercontract_erp_id)
			AND (@is_ots IS NULL OR (@is_ots = 1 AND rmi.ots_id IS NOT NULL) OR (@is_ots = 0 AND rmi.ots_id IS NULL))
	ORDER BY
		di.doc_id                         DESC
GO