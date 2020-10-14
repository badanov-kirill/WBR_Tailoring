CREATE PROCEDURE Products.ProdArticleForPortal
	@xml_data XML = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	DECLARE @data_tab TABLE (
	        	brand_name VARCHAR(50),
	        	sa_imt VARCHAR(68),
	        	sa_nm VARCHAR(36),
	        	ts_name VARCHAR(15),
	        	subject_name VARCHAR(50),
	        	kind_name VARCHAR(50),
	        	sa2_imt VARCHAR(68),
	        	sa2_nm VARCHAR(36)
	        )
	
	DECLARE @pa_tab TABLE(pa_id INT)
	
	INSERT INTO @data_tab
		(
			brand_name,
			sa_imt,
			sa_nm,
			ts_name,
			subject_name,
			kind_name,
			sa2_imt,
			sa2_nm
		)
	VALUES
		(
			'Colambetta',
			'к0220320д0/',
			'311',
			'40',
			'Юбки',
			'Женский',
			'к0220320д1/',
			'310'
		),
	('Colambetta', 'к0220320д0/', '312', '40', 'Юбки', 'Женский', 'к0220320д1/', '117'),
	('Stets', 'st0220320д0/', '200', '40', 'Блузки', 'Женский', '0520220д1/', '119')
	
	INSERT INTO @pa_tab
		(
			pa_id
		)
	SELECT	DISTINCT pa.pa_id
	FROM	@data_tab dt   
			INNER JOIN	Products.Brand b
				ON	b.brand_name = dt.brand_name   
			INNER JOIN	Products.ProdArticle pa
				ON	pa.brand_id = b.brand_id
				AND	pa.sa = dt.sa2_imt   
	
	
	SELECT	pa.pa_id,
			dt.subject_name [f105],
			dt.brand_name [f100],
			dt.sa_imt [f101],
			dt.sa_nm [f102],
			dt.ts_name [f113],
			ISNULL(s.imt_name, sj.subject_name_sf) [f103],
			'%' + CAST(pants.pants_id AS VARCHAR(10)) [f104],
			k.kind_name [f124],
			'Нет' [f109],
			c.collection_name [f114],
			sn.season_name [f115],
			d.direction_name [f120],
			20 [f108],
			STUFF(artcol.x, 1, 1, '') [f106],
			STUFF(cons.x, 1, 1, '') [f107],
			'Россия' [f110],
			s.descr [f111],
			STUFF(con.x, 1, 1, '') [f112],
			ts.ts_name [f119],
			pants.pants_id [f121],
			t.tnved_cod [f123]
	FROM	@data_tab dt   
			INNER JOIN	Products.Brand b
				ON	b.brand_name = dt.brand_name   
			INNER JOIN	Products.TechSize ts
				ON	ts.ts_name = dt.ts_name   
			INNER JOIN	Products.ProdArticle pa
				ON	pa.brand_id = b.brand_id
				AND	pa.sa = dt.sa2_imt   
			INNER JOIN	Products.ProdArticleNomenclature pan
				ON	pan.pa_id = pa.pa_id
				AND	pan.sa = dt.sa2_nm   
			INNER JOIN	Products.ProdArticleNomenclatureTechSize pants
				ON	pants.pan_id = pan.pan_id
				AND	pants.ts_id = ts.ts_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = pa.sketch_id   
			INNER JOIN	Products.[Subject] sj
				ON	sj.subject_id = s.subject_id   
			INNER JOIN	Products.Kind k
				ON	k.kind_id = s.kind_id   
			LEFT JOIN	Products.[Collection] c
				ON	c.collection_id = pa.collection_id   
			INNER JOIN	Products.Season sn
				ON	sn.season_id = ISNULL(pa.season_id, s.season_id)   
			LEFT JOIN	Products.Direction d
				ON	d.direction_id = pa.direction_id   
			OUTER APPLY (
			      	SELECT	';' + CAST(pac.percnt AS VARCHAR(900)) + '% ' + cast(c.consist_name AS VARCHAR(900))
			      	FROM	Products.ProdArticleConsist pac   
			      			INNER JOIN	Products.Consist c
			      				ON	c.consist_id = pac.consist_id
			      	WHERE	pac.pa_id = pa.pa_id
			      	FOR XML	PATH('')
			      ) cons(x)OUTER APPLY (
			                     	SELECT	';' + cast(col.color_name AS VARCHAR(900))
			                     	FROM	Products.ProdArticleNomenclatureColor panc   
			                     			INNER JOIN	Products.Color col
			                     				ON	col.color_cod = panc.color_cod
			                     	WHERE	panc.pan_id = pan.pan_id
			                     	ORDER BY
			                     		CASE 
			                     		     WHEN panc.is_main = 1 THEN 0
			                     		     ELSE 1
			                     		END
			                     	FOR XML	PATH('')
			                     ) artcol(x)OUTER APPLY (
			                                      	SELECT	';' + cast(c.contents_name AS VARCHAR(900))
			                                      	FROM	Products.SketchContent sc   
			                                      			INNER JOIN	Products.[Content] c
			                                      				ON	c.contents_id = sc.contents_id
			                                      	WHERE	sc.sketch_id = s.sketch_id
			                                      	FOR XML	PATH('')
			                                      ) con(x)OUTER APPLY (
			                                                    	SELECT	TOP(1) c.consist_type_id
			                                                    	FROM	Products.ProdArticleConsist pac   
			                                                    			INNER JOIN	Products.Consist c
			                                                    				ON	c.consist_id = pac.consist_id
			                                                    	WHERE	pac.pa_id = pa.pa_id
			                                                    	ORDER BY
			                                                    		pac.percnt DESC
			                                                    ) oa_ct
	LEFT JOIN	Products.TNVED_Settigs tnvds
				INNER JOIN Products.TNVED t
				ON t.tnved_id = tnvds.tnved_id
				ON	tnvds.subject_id = s.subject_id
				AND	tnvds.ct_id = s.ct_id
				AND	tnvds.consist_type_id = oa_ct.consist_type_id
				
	
	SELECT	dt.pa_id,
			vp.content_id,
			stuff(oaopt.x, 1,1,'') opt
	FROM	@pa_tab dt   
			INNER JOIN	(SELECT	paao.pa_id,
			    	     	 		ao.content_id
			    	     	 FROM	Products.ProdArticleAddedOption paao   
			    	     	 		INNER JOIN	Products.AddedOption ao
			    	     	 			ON	ao.ao_id = paao.ao_id
			    	     	 GROUP BY
			    	     	 	paao.pa_id,
			    	     	 	ao.content_id)vp
				ON	vp.pa_id = dt.pa_id   
			OUTER APPLY (
			      	SELECT	';' + isnull(cast(paao2.ao_value AS VARCHAR(900)), cast(ao2.ao_name AS VARCHAR(900)))
			      	FROM	Products.ProdArticleAddedOption paao2   
			      			INNER JOIN	Products.AddedOption ao2 ON ao2.ao_id = paao2.ao_id
			      	WHERE	paao2.pa_id = dt.pa_id
			      			AND	ao2.content_id = vp.content_id
			      	FOR XML	PATH('')
			      ) oaopt(x)