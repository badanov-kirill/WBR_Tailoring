CREATE PROCEDURE [Reports].[DeleteProductOperation_Get]
	@start_dt DATE,
	@finish_dt DATE
AS 
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	SELECT po.po_id,
	       po.product_unic_code,
	       po.operation_id,
	       o.operation_name,
	       puc.pt_id,
	       pt.pt_name,
	       pt.pt_rate,
	       po.office_id,
	       bo.office_name,
	       po.employee_id,
	       CAST(po.dt AS DATETIME) dt,
	       po.delete_employee_id,
	       CAST(po.delete_dt AS DATETIME) delete_dt,	       
	       po.product_unic_code product_shk
	FROM   Manufactory.DeleteProductOperations AS po
		   LEFT JOIN Manufactory.ProductUnicCode puc
				ON puc.product_unic_code = po.product_unic_code
	       LEFT JOIN Manufactory.Operation AS o
	            ON  o.operation_id = po.operation_id
	       LEFT JOIN Products.ProductType AS pt
	            ON  pt.pt_id = puc.pt_id
	       LEFT JOIN Settings.OfficeSetting AS bo
	            ON  bo.office_id = po.office_id  
	WHERE  po.dt BETWEEN @start_dt AND @finish_dt
	
	