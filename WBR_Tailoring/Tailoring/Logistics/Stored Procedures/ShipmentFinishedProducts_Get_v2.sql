CREATE PROCEDURE [Logistics].[ShipmentFinishedProducts_Get_v2]
	@src_office_id INT = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	s.sfp_id,
			CAST(s.create_dt AS DATETIME) create_dt,
			s.create_employee_id,
			s.complite_employee_id          close_employee_id,
			CAST(s.complite_dt AS DATETIME) complite_dt,
			s.complite_employee_id,
			s.src_office_id,
			os.office_name                  src_office_name,
			CAST(s.plan_dt AS DATETIME)     plan_dt,
			oap.cnt                         box_count
	FROM	Logistics.ShipmentFinishedProducts s   
			INNER JOIN	Settings.OfficeSetting os
				ON	s.src_office_id = os.office_id   
			OUTER APPLY (
			      	SELECT	COUNT(1) cnt
			      	FROM	Logistics.PlanShipmentFinishedProductsPackingBox psfppb
			      	WHERE	psfppb.sfp_id = s.sfp_id
			      )                         oap
	WHERE	s.close_planing_dt IS NULL
			AND	s.complite_dt IS NULL
			AND	(@src_office_id IS NULL OR s.src_office_id = @src_office_id)