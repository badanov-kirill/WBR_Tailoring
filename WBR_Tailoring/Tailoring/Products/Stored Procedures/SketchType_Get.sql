CREATE PROCEDURE [Products].[SketchType_Get]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	st.st_id,
			st.st_name
	FROM	Products.SketchType st
	ORDER BY st.st_id