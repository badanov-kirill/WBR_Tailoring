CREATE PROCEDURE [Reports].[SketchGetByRMT]
	@rmt_id INT
AS
	SET NOCOUNT ON 
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	
	SELECT	s.sketch_id,
			s.pic_count,
			s.tech_design,
			s2.subject_name,
			an.art_name,
			b.brand_name,
			s.sa,
			ct.ct_name,
			ss.ss_name
	FROM	Products.Sketch s   
			INNER JOIN	Products.SketchStatus ss
				ON	ss.ss_id = s.ss_id   
			INNER JOIN	Products.[Subject] s2
				ON	s2.subject_id = s.subject_id   
			LEFT JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id   
			LEFT JOIN	Products.Brand b
				ON	b.brand_id = s.brand_id   
			LEFT JOIN	Material.ClothType ct
				ON	ct.ct_id = s.ct_id
	WHERE	s.is_deleted = 0
			AND s.ss_id > 9
			AND	(
			   		EXISTS (
			   			SELECT	TOP(1) 1
			   			FROM	Products.SketchCompleting sc   
			   					LEFT JOIN	Products.SketchCompletingRawMaterial scrm
			   						ON	scrm.sc_id = sc.sc_id
			   			WHERE	sc.sketch_id = s.sketch_id
			   					AND	(sc.base_rmt_id = @rmt_id OR scrm.rmt_id = @rmt_id)
			   		)			   		
			   	)
	ORDER BY
		s.sketch_id DESC