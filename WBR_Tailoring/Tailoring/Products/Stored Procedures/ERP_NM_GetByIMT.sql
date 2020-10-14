CREATE PROCEDURE [Products].[ERP_NM_GetByIMT]
	@imt_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	ens.nm_id,
			ens.sa
	FROM	Products.ERP_NM_Sketch ens
	WHERE	ens.imt_id = @imt_id