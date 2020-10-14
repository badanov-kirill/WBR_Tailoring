CREATE PROCEDURE [Logistics].[ShipmentFinishedProducts_Get]
	@start_dt DATETIME,
	@finish_dt DATETIME,
	@src_office_id INT = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	s.sfp_id,
			CAST(s.create_dt AS DATETIME) create_dt,
			s.create_employee_id,
			CAST(s.complite_dt AS DATETIME) close_dt,
			s.complite_employee_id close_employee_id,
			CAST(s.complite_dt AS DATETIME) complite_dt,
			s.complite_employee_id,
			s.src_office_id,
			os.office_name src_office_name
	FROM	Logistics.ShipmentFinishedProducts s   
			INNER JOIN	Settings.OfficeSetting os
				ON	s.src_office_id = os.office_id
	WHERE	s.create_dt >= @start_dt
			AND	s.create_dt <= @finish_dt
			AND	(@src_office_id IS NULL OR s.src_office_id = @src_office_id)
	
