CREATE PROCEDURE [Logistics].[PackingBox_GetByID]
@packing_box_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	UPDATE	pb
	SET 	pb.close_dt = NULL,
			pb.close_employee_id = NULL
	FROM	Logistics.PackingBox pb
	WHERE	pb.packing_box_id = @packing_box_id
			AND	pb.close_dt IS NOT NULL
			AND	NOT EXISTS(
			   		SELECT	1
			   		FROM	Logistics.PackingBoxDetail pbd
			   		WHERE	pbd.packing_box_id = pb.packing_box_id
			   	)
	
	
	SELECT	pb.packing_box_id,
			CAST(pb.close_dt AS DATETIME) close_dt
	FROM	Logistics.PackingBox pb
	WHERE	pb.packing_box_id = @packing_box_id