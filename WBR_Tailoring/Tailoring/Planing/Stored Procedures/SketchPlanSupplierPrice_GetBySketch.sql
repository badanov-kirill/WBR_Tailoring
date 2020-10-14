CREATE PROCEDURE [Planing].[SketchPlanSupplierPrice_GetBySketch]
	@sketch_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	s.supplier_name,
			spsp.price_ru,
			spsp.comment,
			spsp.order_num,
			CAST(spsp.dt AS DATETIME) dt
	FROM	Planing.SketchPlanSupplierPrice spsp   
			INNER JOIN	Planing.SketchPlan sp
				ON	sp.sp_id = spsp.sp_id   
			INNER JOIN	Suppliers.Supplier s
				ON	s.supplier_id = spsp.supplier_id
	WHERE sp.sketch_id = @sketch_id