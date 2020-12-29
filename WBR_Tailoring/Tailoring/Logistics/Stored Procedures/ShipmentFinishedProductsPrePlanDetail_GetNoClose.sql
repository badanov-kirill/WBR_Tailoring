CREATE PROCEDURE [Logistics].[ShipmentFinishedProductsPrePlanDetail_GetNoClose]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	sfpppd.pants_id,
			SUM(sfpppd.cnt) cnt
	FROM	Logistics.ShipmentFinishedProductsPrePlanDetail sfpppd   
			INNER JOIN	Logistics.ShipmentFinishedProducts sfp
				ON	sfp.sfp_id = sfpppd.sfp_id
	WHERE	sfp.close_planing_dt IS NULL
			AND	sfpppd.cnt > 0
	GROUP BY
		sfpppd.pants_id