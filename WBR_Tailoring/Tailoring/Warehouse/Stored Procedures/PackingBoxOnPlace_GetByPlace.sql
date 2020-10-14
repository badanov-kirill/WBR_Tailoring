CREATE PROCEDURE [Warehouse].[PackingBoxOnPlace_GetByPlace]
	@place_id INT = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	pbop.packing_box_id,
			oa.cnt
	FROM	Warehouse.PackingBoxOnPlace pbop   
			OUTER APPLY (
			      	SELECT	COUNT(1) cnt
			      	FROM	Logistics.PackingBoxDetail pbd
			      	WHERE	pbd.packing_box_id = pbop.packing_box_id
			      ) oa
	WHERE	pbop.place_id = @place_id
	ORDER BY
		pbop.dt