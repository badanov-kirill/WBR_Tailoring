CREATE PROCEDURE [Planing].[SketchPlanSupplierPrice_Get]
	@sp_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	spsp.spsp_id,
			spsp.sp_id,
			spsp.supplier_id,
			s.supplier_name,
			spsp.price_ru,
			CAST(spsp.dt AS DATETIME) dt,
			spsp.employee_id,
			spsp.comment,
			spsp.order_num
	FROM	Planing.SketchPlanSupplierPrice spsp   
			INNER JOIN	Suppliers.Supplier s
				ON	s.supplier_id = spsp.supplier_id
	WHERE spsp.sp_id = @sp_id