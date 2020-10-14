CREATE PROCEDURE [Products].[SketchLogicStatusDict_Get]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	slsd.sls_id,
			slsd.sls_name,
			slsd.sls_short_name
	FROM	Products.SketchLogicStatusDict slsd