CREATE PROCEDURE [Products].[SketchConstructionSale_GetByIDs]
@id_tab dbo.List READONLY
AS
	SET NOCOUNT ON 
	
	SELECT	s.sketch_id,
			s.sa,
			STUFF(oats.x, 1 ,1 , '') ts,
			oa.nm_id,
			sj.subject_name,
			spp.price 
	FROM	Products.Sketch s   
			INNER JOIN	Products.[Subject] sj
				ON	sj.subject_id = s.subject_id   
			INNER JOIN	@id_tab d
				ON	s.sketch_id = d.id  
			LEFT JOIN Products.SubjectsPatternPrice spp
				ON spp.subject_id = s.subject_id 
			OUTER APPLY (
			      	SELECT	TOP(1) pan.nm_id
			      	FROM	Products.ProdArticle pa   
			      			INNER JOIN	Products.ProdArticleNomenclature pan
			      				ON	pan.pa_id = pa.pa_id
			      	WHERE	pa.sketch_id = s.sketch_id
			      			AND	pan.nm_id IS NOT NULL
			      	ORDER BY
			      		pan.nm_id DESC
			      )oa
			OUTER APPLY (
	      			SELECT	';' + ts.ts_name 
	      			FROM	Products.SketchTechSize sts   
	      					INNER JOIN	Products.TechSize ts
	      						ON	ts.ts_id = sts.ts_id
	      			WHERE	sts.sketch_id = s.sketch_id
	      			ORDER BY ts.ts_name
	      			FOR XML	PATH('')
				  ) oats(x)
	
	SELECT	sc.sketch_id,
			sc.completing_id,
			c.completing_name,
			sc.completing_number,
			sc.frame_width,
			sc.okei_id,
			o.symbol         okei_symbol,
			sc.consumption,
			rmt.rmt_name     base_rmt_name
	FROM	Products.SketchCompleting sc   
			INNER JOIN	Material.Completing c
				ON	c.completing_id = sc.completing_id   
			INNER JOIN	Qualifiers.OKEI o
				ON	o.okei_id = sc.okei_id   
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = sc.base_rmt_id	

	WHERE	sc.is_deleted = 0
			AND	EXISTS (
			   		SELECT	1
			   		FROM	@id_tab d
			   		WHERE	d.id = sc.sketch_id
			   	)
	ORDER BY
		sc.sketch_id,
		ISNULL(c.visible_queue, c.completing_id),
		c.completing_id,
		sc.completing_number