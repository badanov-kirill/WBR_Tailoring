CREATE PROCEDURE [Logistics].[Vehicle_Get]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	v.vehicle_id,
			v.brand_name,
			v.number_plate
	FROM	Logistics.Vehicle v
