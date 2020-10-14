CREATE PROCEDURE [Products].[SketchStatus_Get]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	ss.ss_id,
			ISNULL(ss.ss_short_name, ss.ss_name) ss_name
	FROM	Products.SketchStatus ss
	ORDER BY
		ISNULL(ss.ss_short_name, '99') ASC,
		ss.ss_id