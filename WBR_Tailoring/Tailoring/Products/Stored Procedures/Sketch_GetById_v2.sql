CREATE PROCEDURE [Products].[Sketch_GetById_v2]
	@sketch_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	
	SELECT	s.sketch_id,
			s.st_id,
			st.st_name,
			s.ss_id,
			ss.ss_name,
			s.pic_count,
			s.tech_design,
			s.descr,
			s.is_deleted,
			s.kind_id,
			k.kind_name,
			s.subject_id,
			s2.subject_name,
			s.create_employee_id,
			CAST(s.create_dt AS DATETIME) create_dt,
			s.employee_id,
			CAST(s.dt AS DATETIME)     dt,
			CAST(s.rv AS BIGINT)       rv_bigint,
			s.qp_id,
			s.status_comment,
			s.model_year,
			s.brand_id,
			b.brand_name,
			s.season_id,
			sn.season_name,
			s.style_id,
			sl.style_name,
			s.wb_size_group_id,
			wsg.wb_size_group_description,
			an.art_name,
			s.constructor_employee_id,
			s.pattern_name,
			s.sa_local,
			s.sa,
			s.ct_id,
			ct.ct_name,
			s.direction_id,
			s.imt_name,
			oa_so.office_name sew_office_name,
			s.season_model_year, 
			s.season_local_id,
			s.is_china_sample,
			CASE 
			     WHEN scs.sketch_id IS NOT NULL THEN 1
			     ELSE 0
			END construction_sale,
			kw.key_word
	FROM	Products.Sketch s   
			INNER JOIN	Products.SketchStatus ss
				ON	ss.ss_id = s.ss_id   
			INNER JOIN	Products.SketchType st
				ON	st.st_id = s.st_id   
			INNER JOIN	Products.[Subject] s2
				ON	s2.subject_id = s.subject_id   
			LEFT JOIN	Products.Kind k
				ON	k.kind_id = s.kind_id   
			LEFT JOIN	Products.Brand b
				ON	b.brand_id = s.brand_id   
			LEFT JOIN	Products.Season sn
				ON	sn.season_id = s.season_id   
			LEFT JOIN	Products.Style sl
				ON	sl.style_id = s.style_id   
			LEFT JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id   
			LEFT JOIN	Material.ClothType ct
				ON	ct.ct_id = s.ct_id   
			LEFT JOIN	Products.WbSizeGroup wsg
				ON	wsg.wb_size_group_id = s.wb_size_group_id
			LEFT JOIN Products.SketchConstructionSale scs
				ON scs.sketch_id = s.sketch_id
			LEFT JOIN Products.KeyWords kw
				ON kw.kw_id = s.kw_id
			OUTER APPLY (
			      	SELECT	TOP(1) os.office_name
			      	FROM	Planing.SketchPlan sp   
			      			INNER JOIN	Settings.OfficeSetting os
			      				ON	os.office_id = sp.sew_office_id
			      	WHERE	sp.sketch_id = s.sketch_id
			      			AND	sp.sew_office_id IS NOT NULL
			      	ORDER BY
			      		sp.sp_id DESC
			      ) oa_so
	WHERE	s.sketch_id = @sketch_id
	
	SELECT	sc.contents_id,
			c.contents_name
	FROM	Products.SketchContent sc   
			INNER JOIN	Products.Content c
				ON	c.contents_id = sc.contents_id
	WHERE	sc.sketch_id = @sketch_id
	
	SELECT	sts.ts_id,
			spp.perimetr
	FROM	Products.SketchTechSize sts   
			LEFT JOIN	Products.SketchPatternPerimetr spp
				ON	spp.sketch_id = sts.sketch_id
				AND	spp.ts_id = sts.ts_id
	WHERE	sts.sketch_id = @sketch_id
	
	SELECT	pa.pa_id,
			pa.is_deleted,
			pa.descr,
			pa.brand_id,
			pa.season_id,
			pa.collection_id,
			pa.style_id,
			pa.direction_id,
			pa.create_employee_id,
			pa.create_dt,
			pa.model_number,
			oa_color.x [ColorsArticle],
			oa.x             ao,
			oa_consist.x     consist,
			pa.ao_ts_id,
			pa.imt_id,
			pa.is_not_new,
			pa.sa,
			oa_ts.x [TechSizeArticle],
			pa.cut_comment, 
			pa.sew_comment,
			oa_ozon.x ao_ozon
	FROM	Products.ProdArticle pa   
			OUTER APPLY (
			      	SELECT	pan.sa'@sanm',
			      			c.color_name '@colr',
			      			panc.color_cod '@cid',
			      			panc.is_main '@m',
			      			pan.nm_id '@nm',
			      			pan.whprice '@whpr',
			      			pan.price_ru '@pr',
			      			pan.pan_id '@pan'
			      	FROM	Products.ProdArticleNomenclature pan   
			      			INNER JOIN	Products.ProdArticleNomenclatureColor panc
			      				ON	panc.pan_id = pan.pan_id   
			      			INNER JOIN	Products.Color c
			      				ON	c.color_cod = panc.color_cod
			      	WHERE	pan.pa_id = pa.pa_id
			      	ORDER BY
			      		pan.sa ASC,
			      		panc.is_main DESC
			      	FOR XML	PATH('art'), ROOT('arts')
			      ) oa_color(x)
			OUTER APPLY (
			       SELECT	paco.consist_id '@id',
			       		con.consist_name '@name',
			       		paco.percnt '@per'
			       FROM	Products.ProdArticleConsist paco   
			       		INNER JOIN	Products.Consist con
			       			ON	con.consist_id = paco.consist_id
			       WHERE	paco.pa_id = pa.pa_id
			       FOR XML	PATH('con'), ROOT('cons')
			       ) oa_consist(x)
			OUTER APPLY (
			          	SELECT	paao.ao_id '@id',
			          			paao.ao_value '@val',
			          			paao.si_id '@si'
			          	FROM	Products.ProdArticleAddedOption paao
			          	INNER JOIN Products.AddedOption ao ON ao.ao_id = paao.ao_id
			          	WHERE	paao.pa_id = pa.pa_id
			          	AND ao.isdeleted = 0
			          	FOR XML	PATH('ao'), ROOT('aos')
			          ) oa(x)
			OUTER APPLY (
             	SELECT	pan.sa'@sanm',
             			ts.ts_name '@name',
             			ts.ts_id '@id'
             	FROM	Products.ProdArticleNomenclature pan   
             			INNER JOIN	Products.ProdArticleNomenclatureTechSize pants
             				ON	pants.pan_id = pan.pan_id   
             			INNER JOIN	Products.TechSize ts
             				ON	ts.ts_id = pants.ts_id
             	WHERE	pan.pa_id = pa.pa_id
             			AND	pants.is_deleted = 0
             	ORDER BY
             		pan.sa ASC
             	FOR XML	PATH('tart'), ROOT('tarts')
             ) oa_ts(x)
             OUTER APPLY (
			          	SELECT v.attribute_id '@id', v.av_id '@av_id', v.attribute_value '@val'
			          	FROM ( 
			          	SELECT paav.attribute_id, paav.av_id, NULL attribute_value
			          	FROM Ozon.ProdArticleAttributeValues paav
			          	WHERE paav.pa_id = pa.pa_id
			          	UNION ALL
			          	SELECT paa.attribute_id, NULL, paa.attribute_value
			          	FROM Ozon.ProdArticleAttribute paa
			          	WHERE paa.pa_id = pa.pa_id ) v
			          	FOR XML	PATH('attr'), ROOT('aos_ozon')
			          ) oa_ozon(x)
	WHERE	pa.sketch_id = @sketch_id
			AND	pa.is_deleted = 0
	ORDER BY
		pa.pa_id          ASC
	
	SELECT	sc.completing_id,
			c.completing_name,
			sc.completing_number,
			sc.frame_width,
			sc.okei_id,
			o.symbol         okei_symbol,
			sc.consumption,
			sc.comment,
			oa.x             rmts,
			rmt.rmt_name     base_rmt_name
	FROM	Products.SketchCompleting sc   
			INNER JOIN	Material.Completing c
				ON	c.completing_id = sc.completing_id   
			INNER JOIN	Qualifiers.OKEI o
				ON	o.okei_id = sc.okei_id   
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = sc.base_rmt_id   
			OUTER APPLY (
			      	SELECT	scrm.rmt_id '@id',
			      			rmt.rmt_name '@name',
			      			CASE 
			      			     WHEN scrm.rmt_id = sc.base_rmt_id THEN 1
			      			     ELSE 0
			      			END '@m'
			      	FROM	Products.SketchCompletingRawMaterial scrm   
			      			INNER JOIN	Material.RawMaterialType rmt
			      				ON	rmt.rmt_id = scrm.rmt_id
			      	WHERE	scrm.sc_id = sc.sc_id
			      	FOR XML	PATH('rmt'), ROOT('rmts')
			      ) oa(x)
	WHERE	sc.is_deleted = 0
			AND	sc.sketch_id = @sketch_id
	ORDER BY ISNULL(c.visible_queue, c.completing_id), c.completing_id, sc.completing_number