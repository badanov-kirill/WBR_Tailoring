CREATE PROCEDURE [Reports].[PaymentDelay]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	DECLARE @dt DATE = GETDATE()
	DECLARE @start_dt DATE = DATEADD(DAY, -60, @dt)
	DECLARE @finish_dt DATE = DATEADD(DAY, 90, @dt)
	
	SELECT	s.supplier_name,
			sc.suppliercontract_name,
			sc.payment_delay_day,
			rmi.doc_id,
			STUFF(oa_inv.x, 1, 3, '') invoices,
			oa.amount,
			CAST(rmi.goods_dt AS DATETIME) goods_dt,
			CAST(DATEADD(DAY, sc.payment_delay_day, rmi.goods_dt) AS DATETIME) payment_delay_dt
	FROM	Material.RawMaterialIncome rmi   
			INNER JOIN	Suppliers.SupplierContract sc
				ON	sc.suppliercontract_id = rmi.suppliercontract_id   
			INNER JOIN	Suppliers.Supplier s
				ON	s.supplier_id = sc.supplier_id   
			OUTER APPLY (
			      	SELECT	SUM(rminvd.amount_with_nds) amount
			      	FROM	Material.RawMaterialInvoice rminv   
			      			INNER JOIN	Material.RawMaterialInvoiceDetail rminvd
			      				ON	rminvd.rmi_id = rminv.rmi_id
			      	WHERE	rminv.doc_id = rmi.doc_id
			      			AND	rminv.doc_type_id = rmi.doc_type_id
			      			AND	rminv.is_deleted = 0
			      ) oa
	OUTER APPLY (
	      	SELECT	' ; ' + rminv.invoice_name + ' от ' + CAST(rminv.invoice_dt AS VARCHAR(20)) + ''
	      	FROM	Material.RawMaterialInvoice rminv
	      	WHERE	rminv.doc_id = rmi.doc_id
	      			AND	rminv.doc_type_id = rmi.doc_type_id
	      			AND	rminv.is_deleted = 0
	      	FOR XML	PATH('')
	      ) oa_inv(x)
	WHERE	sc.payment_delay_day IS NOT NULL
			AND	DATEADD(DAY, sc.payment_delay_day, rmi.goods_dt) BETWEEN @start_dt AND @finish_dt
			AND	EXISTS (
			   		SELECT	1
			   		FROM	Material.RawMaterialIncomeDetail rmid
			   		WHERE	rmid.doc_id = rmi.doc_id
			   				AND	rmid.doc_type_id = rmi.doc_type_id
			   	)
	ORDER BY
		DATEADD(DAY, sc.payment_delay_day, rmi.goods_dt)