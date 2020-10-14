CREATE PROCEDURE [Manufactory].[Sample_GetById]
	@sample_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	sam.sample_id,
			b.brand_name,
			sj.subject_name,
			an.art_name,
			s.sa,
			s.sketch_id,
			st.st_name
	FROM	Manufactory.[Sample] sam   
			INNER JOIN	Manufactory.SampleType st
				ON	st.st_id = sam.st_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = sam.sketch_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id   
			INNER JOIN	Products.[Subject] sj
				ON	sj.subject_id = s.subject_id   
			INNER JOIN	Products.Brand b
				ON	b.brand_id = s.brand_id
	WHERE	sam.sample_id = @sample_id