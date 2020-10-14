CREATE PROCEDURE [Material].[RawMaterialIncomeStatus_Get]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	rmis.rmis_id,
			rmis.rmis_name
	FROM	Material.RawMaterialIncomeStatus rmis