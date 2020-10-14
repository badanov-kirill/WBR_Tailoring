CREATE PROCEDURE [Products].[ArtName_Get]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	an.art_name_id,
			an.art_name,
			s.sa,
			cast(an.dt AS DATETIME) dt
	FROM	Products.ArtName an    
			LEFT JOIN Products.Sketch s
				ON	s.art_name_id = an.art_name_id