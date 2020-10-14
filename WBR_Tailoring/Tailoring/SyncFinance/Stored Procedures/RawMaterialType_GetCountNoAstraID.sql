CREATE PROCEDURE [SyncFinance].[RawMaterialType_GetCountNoAstraID]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	COUNT(1)                     cnt
	FROM	Material.RawMaterialType     rmt
	WHERE	rmt.rmt_astra_id IS NULL