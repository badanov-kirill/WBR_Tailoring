CREATE PROCEDURE [Products].[ProdArticle_GetByERP_v3]
	@pa_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	IF EXISTS (
	   	SELECT	1
	   	FROM	Products.ProdArticleNomenclature pan   
	   			LEFT JOIN	Products.ProdArticleNomenclatureTechSize pants
	   				ON	pants.pan_id = pan.pan_id
	   	WHERE	pan.pa_id = @pa_id
	   			AND	pants.pan_id IS NULL
	   )
	BEGIN
		RAISERROR('Есть цвет без размеров',16,1)
		RETURN
	END
	
	SELECT	pa.pa_id,
			pa.model_number                 pa_number,
			ISNULL(pa.descr, s.descr)       descr,
			b.erp_id                        brand_id,
			ISNULL(sn.erp_id, sn2.erp_id) season_id,
			cl.erp_id                       collection_id,
			ISNULL(st.erp_id, st2.erp_id) style_id,
			ISNULL(d.erp_id, d2.erp_id)     direction_id,
			k.erp_id                        kind_id,
			sj.erp_id                       subject_id,
			ISNULL(s.imt_name, sj.subject_name_sf) imt_name,
			wsg.erp_id                      wb_size_group_id,
			t.erp_id                        tpgroup_id,
			ISNULL(pa.sa, s.sa + CAST(pa.model_number AS VARCHAR(10)) + '/') sa,
			con.x                           content_xml,
			ts.x                            ts_xml,
			ao.x                            ao_xml,
			cons.x                          consist_xml,
			artcol.x                        art_color_xml,
			tsz.erp_id                      ao_ts_id,
			pa.is_not_new                   is_not_new
	FROM	Products.ProdArticle            pa
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = pa.sketch_id   
			INNER JOIN	Products.Brand b
				ON	b.brand_id = pa.brand_id   
			LEFT JOIN	Products.Season sn
				ON	sn.season_id = pa.season_id   
			INNER JOIN	Products.Season sn2
				ON	sn2.season_id = s.season_id   
			LEFT JOIN	Products.[Collection] cl
				ON	cl.collection_id = pa.collection_id   
			LEFT JOIN	Products.Style st
				ON	st.style_id = pa.style_id   
			LEFT JOIN	Products.Style st2
				ON	st2.style_id = s.style_id   
			LEFT JOIN	Products.Direction d
				ON	d.direction_id = pa.direction_id   
			LEFT JOIN	Products.Direction d2
				ON	d2.direction_id = s.direction_id   
			LEFT JOIN	Products.Kind k
				ON	k.kind_id = s.kind_id   
			LEFT JOIN	Products.[Subject] sj
				ON	sj.subject_id = s.subject_id   
			LEFT JOIN	Products.SubjectKindWbSizeGroup skwsg   
			INNER JOIN	Products.WbSizeGroup wsg
				ON	wsg.wb_size_group_id = skwsg.wb_size_group_id
				ON	skwsg.kind_id = s.kind_id
				AND	skwsg.subject_id = s.subject_id   
			LEFT JOIN	Products.SubjectBrandTPGroup sbt   
			INNER JOIN	Products.TPGroup t
				ON	t.tpgroup_id = sbt.tpgroup_id
				ON	sbt.brand_id = pa.brand_id
				AND	sbt.kind_id = s.kind_id
				AND	sbt.subject_id = s.subject_id 
			LEFT JOIN Products.TechSize tsz
				ON tsz.ts_id = pa.ao_ts_id  
			OUTER APPLY (
		      		SELECT	c.contents_name '@name'
		      		FROM	Products.SketchContent sc   
		      				INNER JOIN	Products.[Content] c
		      					ON	c.contents_id = sc.contents_id
		      		WHERE	sc.sketch_id = s.sketch_id
		      		FOR XML	PATH('con'), ROOT('contents')
				  ) con(x)
			OUTER APPLY (
              		SELECT	pan.sa '@sa',
              				ts.erp_id '@id'
              		FROM	Products.ProdArticleNomenclatureTechSize pants   
              				INNER JOIN	Products.TechSize ts
              					ON	ts.ts_id = pants.ts_id   
              				INNER JOIN	Products.ProdArticleNomenclature pan
              					ON	pan.pan_id = pants.pan_id
              		WHERE	pan.pa_id = pa.pa_id
              		FOR XML	PATH('ts'), ROOT('tss')
				  ) ts(x)
			OUTER APPLY (
		      		SELECT	ao.content_id '@id',
		      				ao.content_ext_id '@ext_id',
		      				CAST(paao.ao_value * ISNULL(si.multiplier, 1) AS DECIMAL(19,8)) '@val',
		      				paao.si_id '@si'
		      		FROM	Products.ProdArticleAddedOption paao   
		      				INNER JOIN	Products.AddedOption ao
		      					ON	ao.ao_id = paao.ao_id
		      				LEFT JOIN Products.SI si 
		      					ON si.si_id = paao.si_id
		      		WHERE	paao.pa_id = pa.pa_id AND ao.content_id IS NOT NULL AND ao.isdeleted = 0
		      		FOR XML	PATH('ao'), ROOT('aos')
				  ) ao(x)
			OUTER APPLY (
		      		SELECT	c.erp_id '@id',
		      				pac.percnt '@perc'
		      		FROM	Products.ProdArticleConsist pac   
		      				INNER JOIN	Products.Consist c
		      					ON	c.consist_id = pac.consist_id
		      		WHERE	pac.pa_id = pa.pa_id
		      		FOR XML	PATH('consist'), ROOT('consists')
				  ) cons(x)
			OUTER APPLY (
		      		SELECT	pan.sa '@sanm',
		      				panc.color_cod '@cid',
		      				panc.is_main '@m'
		      		FROM	Products.ProdArticleNomenclature pan   
		      				INNER JOIN	Products.ProdArticleNomenclatureColor panc
		      					ON	panc.pan_id = pan.pan_id
		      		WHERE	pan.pa_id = pa.pa_id
		      		FOR XML	PATH('art'), ROOT('arts')
				  ) artcol(x)
	WHERE	pa.pa_id = @pa_id