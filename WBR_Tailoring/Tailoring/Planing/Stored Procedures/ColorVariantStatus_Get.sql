CREATE PROCEDURE [Planing].[ColorVariantStatus_Get]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	cvs.cvs_id,
			cvs.cvs_name
	FROM	Planing.ColorVariantStatus cvs