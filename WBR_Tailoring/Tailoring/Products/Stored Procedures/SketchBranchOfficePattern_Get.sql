CREATE PROCEDURE [Products].[SketchBranchOfficePattern_Get]
	@sketch_id INT = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	sbop.sketch_id,
			sbop.office_id
	FROM	Products.SketchBranchOfficePattern sbop
	WHERE	@sketch_id IS NULL
			OR	sbop.sketch_id = @sketch_id 