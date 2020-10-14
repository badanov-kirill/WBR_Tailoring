CREATE PROCEDURE [Logistics].[Driver_Get]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	d.driver_id,
			d.driver_name
	FROM	Logistics.Driver d
