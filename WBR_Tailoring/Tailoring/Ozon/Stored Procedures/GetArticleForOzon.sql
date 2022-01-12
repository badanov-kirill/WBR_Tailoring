CREATE PROCEDURE [Ozon].[GetArticleForOzon]
	@pa_id INT,
	@pan_id INT = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED

	DECLARE @category_id BIGINT
	DECLARE @brand_name VARCHAR(50)
	DECLARE @season_name VARCHAR(50)
	DECLARE @kind_name VARCHAR(50)
	DECLARE @tnved_cod VARCHAR(15)
	DECLARE @sa VARCHAR(100)
	DECLARE @descr VARCHAR(1000)
	DECLARE @consist VARCHAR(1000)
	
	SELECT	@category_id = sc.category_id,
			@brand_name      = b.brand_name,
			@season_name     = sn.season_name,
			@kind_name       = k.kind_name,
			@tnved_cod       = t.tnved_cod,
			@sa				 = ISNULL(pa.sa, s.sa + CAST(pa.model_number AS VARCHAR(10)) + '/'),
			@descr			 = ISNULL(pa.descr, s.descr),
			@consist		 = STUFF(oa_cons.x , 1, 2, '')
	FROM	Products.ProdArticle pa   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = pa.sketch_id   
			LEFT JOIN	Ozon.SubjectsCategories sc
				ON	sc.subject_id = s.subject_id   
			INNER JOIN	Products.Brand b
				ON	b.brand_id = s.brand_id   
			INNER JOIN	Products.Season sn
				ON	sn.season_id = s.season_id   
			INNER JOIN	Products.Kind k
				ON	k.kind_id = s.kind_id   
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
			OUTER APPLY (SELECT	', ' + CAST(pac.percnt AS VARCHAR(10)) + '% ' + c.consist_name
    			 FROM	Products.ProdArticleConsist pac   
    	 				INNER JOIN	Products.Consist c
    	 					ON	c.consist_id = pac.consist_id
    			 WHERE	pac.pa_id = pa.pa_id
    			 ORDER BY
    	 			pac.percnt DESC
    			 FOR XML	PATH(''))oa_cons(x)
	WHERE	pa.pa_id = @pa_id

	SELECT	pa.pa_id,
			@category_id category_id,
			sj.subject_name_sf [name],
			ISNULL(pa.sa, s.sa + CAST(pa.model_number AS VARCHAR(10)) + '/') sa_imt,
			15       height,
			300      depth,
			300      width,
			'mm'     dimension_unit,
			250 [weight],
			'g'      weight_unit
	FROM	Products.ProdArticle pa   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = pa.sketch_id   
			INNER JOIN	Products.[Subject] sj
				ON	sj.subject_id = s.subject_id   
	WHERE	pa.pa_id = @pa_id
	
	SELECT	pan.pan_id,
			pan.sa,
			pan.whprice,
			pan.price_ru,
			pan.nm_id,
			pan.pics_dt
	FROM	Products.ProdArticleNomenclature pan 
	WHERE	pan.pa_id = @pa_id
			AND	pan.is_deleted = 0 
			AND (@pan_id IS NULL OR pan.pan_id = @pan_id)
			--AND ISNULL(pan.price_ru, 0) > 0 

	SELECT	pan.pan_id,
			MAX(c.color_name) color_name,
			ISNULL(oa_ozon_color.av_id, oa_ozon_color2.av_id) av_id,
			MAX(CAST(panc.is_main AS TINYINT)) is_main
	FROM	Products.ProdArticleNomenclature pan   
			LEFT JOIN	Products.ProdArticleNomenclatureColor panc
				ON	panc.pan_id = pan.pan_id   
			LEFT JOIN	Products.Color c
				ON	c.color_cod = panc.color_cod   
			LEFT JOIN	Products.Color pc
				ON	pc.color_cod = c.color_cod_parent   
			OUTER APPLY (
			      	SELECT	TOP(1) av.av_id
			      	FROM	Ozon.AttributeValues av   
			      			INNER JOIN	Ozon.CategoriesAttributeValues cav
			      				ON	cav.av_id = av.av_id
			      	WHERE	cav.attribute_id = 10096
			      			AND	cav.category_id = @category_id
			      			AND	av.av_value = c.color_name
			      ) oa_ozon_color
			OUTER APPLY (
	      			SELECT	TOP(1) av.av_id
	      			FROM	Ozon.AttributeValues av   
	      					INNER JOIN	Ozon.CategoriesAttributeValues cav
	      						ON	cav.av_id = av.av_id
	      			WHERE	cav.attribute_id = 10096
	      					AND	cav.category_id = @category_id
	      					AND	av.av_value = pc.color_name
				  ) oa_ozon_color2
	WHERE	pan.pa_id = @pa_id
			AND	pan.is_deleted = 0
			AND (@pan_id IS NULL OR pan.pan_id = @pan_id)
	GROUP BY
		pan.pan_id,
		ISNULL(oa_ozon_color.av_id, oa_ozon_color2.av_id)		
			
	SELECT	pan.pan_id,
			ts.rus_name ts_name,
			e.ean,
			oa_ozon_ts.av_id ozon_ts_id
	FROM	Products.ProdArticleNomenclature pan   
			INNER JOIN	Products.ProdArticleNomenclatureTechSize pants
				ON	pants.pan_id = pan.pan_id   
			INNER JOIN	Products.TechSize ts
				ON	ts.ts_id = pants.ts_id   
			LEFT JOIN	Manufactory.EANCode e
				ON	e.pants_id = pants.pants_id
			OUTER APPLY (
			      	SELECT	TOP(1) av.av_id
			      	FROM	Ozon.AttributeValues av   
			      			INNER JOIN	Ozon.CategoriesAttributeValues cav
			      				ON	cav.av_id = av.av_id
			      	WHERE	cav.attribute_id = 4295
			      			AND	cav.category_id = @category_id
			      			AND av.av_value = ts.rus_name
			) oa_ozon_ts
	WHERE	pan.pa_id = @pa_id
			AND	pan.is_deleted = 0
			AND (@pan_id IS NULL OR pan.pan_id = @pan_id)	 
			
	SELECT	paav.attribute_id,
			paav.av_id,
			NULL attribute_value
	FROM	Ozon.ProdArticleAttributeValues paav   
			INNER JOIN	Ozon.Attributes a
				ON	a.attribute_id = paav.attribute_id   
			INNER JOIN	Ozon.CategoriesAttributes ca
				ON	ca.attribute_id = paav.attribute_id
				AND	ca.category_id = @category_id
	WHERE	paav.pa_id = @pa_id
			AND	a.is_used = 1
			AND	a.attribute_id NOT IN (31, 12121, 4389, 4191)
	UNION ALL 
	SELECT	paa.attribute_id,
			NULL                          av_id,
			paa.attribute_value
	FROM	Ozon.ProdArticleAttribute     paa
	WHERE paa.pa_id = @pa_id
	UNION ALL 
	SELECT	TOP(1) v.attribute_id,	--Бренд
			av.av_id,
			ISNULL(av.av_value, @brand_name)
	FROM	(VALUES(31))v(attribute_id)   
			LEFT JOIN	Ozon.AttributeValues av   
			INNER JOIN	Ozon.CategoriesAttributeValues cav
				ON	cav.av_id = av.av_id
				AND	cav.category_id = @category_id
				ON	av.av_value = @brand_name
				AND	cav.attribute_id = v.attribute_id
	UNION ALL
	--SELECT TOP(1)	v.attribute_id, --Сезон
	--		ISNULL(av.av_id, 30937), --Если неопределено то "На любой сезон"
	--		NULL
	--FROM	(VALUES(4495)) v(attribute_id)
	--		LEFT JOIN	Ozon.AttributeValues av   
	--		INNER JOIN	Ozon.CategoriesAttributeValues cav
	--			ON	cav.av_id = av.av_id
	--			AND	cav.category_id = @category_id
	--			ON	av.av_value = @season_name
	--			AND	cav.attribute_id = v.attribute_id
	--UNION ALL
	--SELECT TOP(1)	v.attribute_id, --Пол
	--		ISNULL(av.av_id, 22881), --Если неопределено то "Женский"
	--		NULL
	--FROM	(VALUES(9163)) v(attribute_id)
	--		LEFT JOIN	Ozon.AttributeValues av   
	--		INNER JOIN	Ozon.CategoriesAttributeValues cav
	--			ON	cav.av_id = av.av_id
	--			AND	cav.category_id = @category_id
	--			ON	av.av_value = @kind_name
	--			AND	cav.attribute_id = v.attribute_id
	--UNION ALL
	SELECT TOP(1)	v.attribute_id, --ТНВД
			av.av_id,
			CASE WHEN av.av_id IS NULL THEN @tnved_cod ELSE av.av_value END
	FROM	(VALUES(12121)) v(attribute_id)
			LEFT JOIN	Ozon.AttributeValues av   
			INNER JOIN	Ozon.CategoriesAttributeValues cav
				ON	cav.av_id = av.av_id
				AND	cav.category_id = @category_id
				ON	LEFT(av.av_value, 4) = LEFT(@tnved_cod, 4)
				AND	cav.attribute_id = v.attribute_id
	UNION ALL
	SELECT 	v.attribute_id, --Страна
			v.av_id, --Россия
			v.val
	FROM	(VALUES(4389, 90295, 'Россия')) v(attribute_id, av_id, val)
	UNION ALL
	SELECT 	v.attribute_id, --Аннотация
			v.av_id,
			v.val
	FROM	(VALUES(4191, NULL, @descr)) v(attribute_id, av_id, val)
	--UNION ALL
	--SELECT 	v.attribute_id, --Состав
	--		v.av_id,
	--		v.val
	--FROM	(VALUES(4604, NULL, @consist)) v(attribute_id, av_id, val)
	--UNION ALL		
	--SELECT 	TOP(1) v.attribute_id, --Целевая аудитория
	--		ISNULL(paav.av_id,v.av_id) av_id,
	--		v.val
	--FROM	(VALUES(9390, 43241, NULL)) v(attribute_id, av_id, val)
	--		INNER JOIN	Ozon.CategoriesAttributeValues cav
	--			ON cav.attribute_id = v.attribute_id
	--			AND	cav.category_id = @category_id
	--		LEFT JOIN Ozon.ProdArticleAttributeValues paav 
	--			ON paav.pa_id = @pa_id	
	--			AND paav.attribute_id = v.attribute_id
	--UNION ALL		
	--SELECT 	TOP(1) v.attribute_id, --Тип упаковки одежды
	--		ISNULL(paav.av_id,v.av_id) av_id,
	--		v.val
	--FROM	(VALUES(4300, 44412, NULL)) v(attribute_id, av_id, val)
	--		INNER JOIN	Ozon.CategoriesAttributeValues cav
	--			ON cav.attribute_id = v.attribute_id
	--			AND	cav.category_id = @category_id
	--		LEFT JOIN Ozon.ProdArticleAttributeValues paav 
	--			ON paav.pa_id = @pa_id	
	--			AND paav.attribute_id = v.attribute_id
	--UNION ALL		
	--SELECT 	TOP(1) v.attribute_id, --Рост
	--		ISNULL(paav.av_id,v.av_id) av_id, --165-170
	--		v.val
	--FROM	(VALUES(4296, 83862, NULL)) v(attribute_id, av_id, val)
	--		INNER JOIN	Ozon.CategoriesAttributeValues cav
	--			ON cav.attribute_id = v.attribute_id
	--			AND	cav.category_id = @category_id
	--		LEFT JOIN Ozon.ProdArticleAttributeValues paav 
	--			ON paav.pa_id = @pa_id	
	--			AND paav.attribute_id = v.attribute_id			
				