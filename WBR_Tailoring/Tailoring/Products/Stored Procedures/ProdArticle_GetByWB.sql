CREATE PROCEDURE [Products].[ProdArticle_GetByWB]
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
	    RAISERROR('Есть цвет без размеров', 16, 1)
	    RETURN
	END
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Products.ProdArticleConsist pac
	   	WHERE	pac.pa_id = @pa_id
	   )
	BEGIN
	    RAISERROR('Не указан состав', 16, 1)
	    RETURN
	END
	
	SELECT	pa.pa_id,
			ISNULL(pa.descr, s.descr)     descr,
			b.brand_name,
			ISNULL(sn.season_name, sn2.season_name) season_name,
			cl.collection_name,
			ISNULL(st.style_name, st2.style_name) style_name,
			ISNULL(d.direction_name, d2.direction_name) direction_name,
			sj.subject_name,
			k.kind_name,
			ISNULL(s.imt_name, sj.subject_name_sf) imt_name,
			ISNULL(pa.sa, s.sa + CAST(pa.model_number AS VARCHAR(10)) + '/') sa_imt,
			STUFF(con.x, 1, 2, '')        contents,
			tsz.rus_name                   ao_ts_name,
			t.tnved_cod,
			s.ct_id,
			oa_ct.consist_type_id,
			'Россия' country_name
	FROM	Products.ProdArticle pa   
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
			LEFT JOIN	Products.TechSize tsz
				ON	tsz.ts_id = pa.ao_ts_id   
			OUTER APPLY (
			      	SELECT	TOP(1) c.consist_type_id
			      	FROM	Products.ProdArticleConsist pac   
			      			INNER JOIN	Products.Consist c
			      				ON	c.consist_id = pac.consist_id
			      	WHERE	pac.pa_id = pa.pa_id
			      	ORDER BY
			      		pac.percnt DESC
			      ) oa_ct
	LEFT JOIN	Products.TNVED_Settigs tnvds
				ON	tnvds.subject_id = s.subject_id
				AND	tnvds.ct_id = s.ct_id
				AND	tnvds.consist_type_id = oa_ct.consist_type_id   
			LEFT JOIN	Products.TNVED t
				ON	t.tnved_id = tnvds.tnved_id   
			OUTER APPLY (
			      	SELECT	'; ' + c.contents_name
			      	FROM	Products.SketchContent sc   
			      			INNER JOIN	Products.[Content] c
			      				ON	c.contents_id = sc.contents_id
			      	WHERE	sc.sketch_id = s.sketch_id
			      	FOR XML	PATH('')
			      ) con(x)
	WHERE	pa.pa_id = @pa_id
	
	SELECT	pan.pan_id,
			pan.nm_id,
			pan.sa,
			mc.color_name main_color,
			STUFF(artcol.x, 1, 2, '') not_nain_colors,
			pan.whprice,
			pan.price_ru
	FROM	Products.ProdArticleNomenclature pan 
			LEFT JOIN Products.ProdArticleNomenclatureColor pancm
			ON pancm.pan_id = pan.pan_id AND pancm.is_main = 1
			LEFT JOIN Products.Color mc
			ON mc.color_cod = pancm.color_cod			  
			OUTER APPLY (
			      	SELECT	'; ' + c.color_name
			      	FROM	Products.ProdArticleNomenclatureColor panc   
			      			INNER JOIN	products.Color c
			      				ON	c.color_cod = panc.color_cod
			      	WHERE	panc.pan_id = pan.pan_id
			      	AND panc.is_main = 0
			      	FOR XML	PATH('')
			      ) artcol(x)
	WHERE	pan.pa_id = @pa_id
			AND	pan.is_deleted = 0	  
	
	SELECT	pan.pan_id,
			ts.rus_name ts_name,
			e.ean
	FROM	Products.ProdArticleNomenclature pan   
			INNER JOIN	Products.ProdArticleNomenclatureTechSize pants
				ON	pants.pan_id = pan.pan_id   
			INNER JOIN	Products.TechSize ts
				ON	ts.ts_id = pants.ts_id   
			LEFT JOIN	Manufactory.EANCode e
				ON	e.pants_id = pants.pants_id
	WHERE	pan.pa_id = @pa_id
			AND	pan.is_deleted = 0	  
	
	SELECT	c.consist_name,
			pac.percnt
	FROM	Products.ProdArticleConsist pac   
			INNER JOIN	Products.Consist c
				ON	c.consist_id = pac.consist_id
	WHERE	pac.pa_id = @pa_id
	ORDER BY
		pac.percnt DESC 
	
	
	SELECT  ao.ao_id_parent,
			aop.ao_name ao_parrent_name,
			ao.ao_name,
			paao.ao_value val,
			si.si_name
	FROM	Products.ProdArticleAddedOption paao   
			INNER JOIN	Products.AddedOption ao
				ON	ao.ao_id = paao.ao_id   
			LEFT JOIN	Products.AddedOption aop
				ON	aop.ao_id = ao.ao_id_parent   
			LEFT JOIN	Products.SI si
				ON	si.si_id = paao.si_id
	WHERE	paao.pa_id = @pa_id
			AND	ao.content_id IS NOT NULL
			AND	ao.isdeleted = 0
	ORDER BY aop.ao_name, aop.ao_id
	