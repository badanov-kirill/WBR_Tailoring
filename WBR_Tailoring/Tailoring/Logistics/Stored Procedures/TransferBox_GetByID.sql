CREATE PROCEDURE [Logistics].[TransferBox_GetByID]
	@transfer_box_id BIGINT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	tb.transfer_box_id,
			CAST(tb.create_dt AS DATETIME) create_dt,
			CAST(tb.close_dt AS DATETIME) close_dt,
			CASE 
			     WHEN tbs.transfer_box_id IS NULL THEN 0
			     ELSE 1
			END is_special,
			CAST(tb.plan_shipping_dt AS DATETIME) plan_shipping_dt
	FROM	Logistics.TransferBox tb   
			LEFT JOIN Logistics.TransferBoxSpecial tbs
				ON tbs.transfer_box_id = tb.transfer_box_id
	WHERE	tb.transfer_box_id = @transfer_box_id