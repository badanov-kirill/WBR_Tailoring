CREATE PROCEDURE [Products].[gs1_gcp_GetAll]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	gg.bric_code_for_api,
			gg.brick_description,
			gg.class_description,
			gg.family_description,
			gg.segment_description,
			gg.local_id
	FROM	Products.gs1_gcp gg
	ORDER BY gg.local_id