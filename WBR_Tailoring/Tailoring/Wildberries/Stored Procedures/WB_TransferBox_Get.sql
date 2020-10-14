CREATE PROCEDURE [Wildberries].[WB_TransferBox_Get]
@packing_box_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	wtb.box_name
	FROM	Wildberries.WB_TransferBox wtb
	WHERE	wtb.packing_box_id = @packing_box_id
