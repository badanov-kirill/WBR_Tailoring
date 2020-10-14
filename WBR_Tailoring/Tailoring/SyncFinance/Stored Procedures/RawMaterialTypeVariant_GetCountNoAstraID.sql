CREATE PROCEDURE [SyncFinance].[RawMaterialTypeVariant_GetCountNoAstraID]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	COUNT(1) cnt
	FROM	Material.RawMaterialTypeVariant rmt
	WHERE	rmt.rmt_astra_id IS NULL
			AND	rmt.art_id IS NOT NULL