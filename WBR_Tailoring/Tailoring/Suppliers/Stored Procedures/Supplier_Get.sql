CREATE PROCEDURE [Suppliers].[Supplier_Get]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	s.supplier_id,
			s.supplier_name + CASE 
			                       WHEN s.supplier_source_id = 1 THEN '[WB]'
			                       WHEN s.supplier_source_id = 2 THEN '[Vas]'
			                       ELSE ''
			                  END     supplier_name,
			oa.suppliercontract_id,
			oa.suppliercontract_name,
			ISNULL(oa.payment_delay_day, 0) payment_delay_day
	FROM	Suppliers.Supplier s   
			CROSS APPLY (
			      	SELECT	TOP(1) sc.suppliercontract_id,
			      			sc.suppliercontract_name,
			      			sc.payment_delay_day
			      	FROM	Suppliers.SupplierContract sc
			      	WHERE	sc.supplier_id = s.supplier_id
			      	ORDER BY
			      		sc.is_default DESC,
			      		sc.suppliercontract_id ASC
			      )                   oa
	WHERE	s.is_deleted = 0
GO