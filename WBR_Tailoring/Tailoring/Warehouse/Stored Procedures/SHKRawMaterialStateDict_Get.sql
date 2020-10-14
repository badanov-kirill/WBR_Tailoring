CREATE PROCEDURE [Warehouse].[SHKRawMaterialStateDict_Get]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	smsd.state_id,
			smsd.state_name,
			smsd.state_descr,
			CAST(smsd.dt AS DATETIME) dt,
			smsd.employee_id
	FROM	Warehouse.SHKRawMaterialStateDict smsd
GO