CREATE PROCEDURE [Products].[ProdArticleForOzon_BySFP]
@sfp_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	DECLARE @pa_tab TABLE(pa_id INT)
	DECLARE @pants_tab TABLE (pants_id INT, pa_id INT, barcode VARCHAR(13), cnt INT)
	
	INSERT INTO @pants_tab
		(
			pants_id,
			pa_id,
			barcode,
			cnt
		)
	SELECT  pants.pants_id,
			pan.pa_id,
			pbd.barcode,
			COUNT(1)
	FROM	Logistics.PlanShipmentFinishedProductsPackingBox psfppb   
			INNER JOIN	Logistics.PackingBoxDetail pbd
				ON	pbd.packing_box_id = psfppb.packing_box_id   
			INNER JOIN	Manufactory.ProductUnicCode puc
				ON	puc.product_unic_code = pbd.product_unic_code   
			LEFT JOIN	Products.ProdArticleNomenclatureTechSize pants   
			INNER JOIN	Products.ProdArticleNomenclature pan
				ON	pan.pan_id = pants.pan_id   
			INNER JOIN	Products.ProdArticle pa
				ON	pa.pa_id = pan.pa_id
				ON	pants.pants_id = puc.pants_id
	WHERE	psfppb.sfp_id = @sfp_id
	GROUP BY pants.pants_id,
			pan.pa_id,
			pbd.barcode
	
	INSERT INTO @pa_tab
		(
			pa_id
		)
	SELECT	DISTINCT pt.pa_id
	FROM	@pants_tab pt
	
	
	SELECT	
	       b.brand_name [Бренд],	
           sj.subject_name [Наименование],	
           sj.subject_name [Название],	
           pa.sa + pan.sa [Модель_товара],	
           '' [Вид_спорта],	
           'Россия' [Страна_производства],		
           c.collection_name [Коллекция],	
           sj.subject_name [Тип_продукта],	
           s.descr [Описание],	
           k.kind_name [Пол],	
           sn.season_name [Сезон],	
           STUFF(artcol.x, 1, 1, '') [Цвет],	
           '' [Укажите_стиль_товара_Вы_можете_выбрать_несколько_стилей_из_выпадающего_списка],	
           STUFF(cons.x, 1, 1, '')  [Состав_изделия],	
           STUFF(con.x, 1, 1, '') [Комплектация],	
           ts2.ts_name [Размер_изделия_на_модели],		
           ISNULL(t.tnved_cod, '6104420000') [ТН_ВЭД],
           dt.barcode [ProductId],	
           pan.price_ru [Цена],	
           ts.ts_name [Размер],	
           pa.sa + pan.sa [ParentSku],	
           pa.sa + pan.sa + '/' + ts.ts_name [артикул/размер]          
	FROM	@pants_tab dt   
			INNER JOIN	Products.ProdArticleNomenclatureTechSize pants
				ON	pants.pants_id = dt.pants_id   
			INNER JOIN	Products.ProdArticleNomenclature pan
				ON	pan.pan_id = pants.pan_id   
			INNER JOIN	Products.ProdArticle pa
				ON	pa.pa_id = pan.pa_id   
			INNER JOIN	Products.Brand b
				ON	b.brand_id = pa.brand_id   
			INNER JOIN	Products.TechSize ts
				ON	ts.ts_id = pants.ts_id
			LEFT JOIN Products.TechSize ts2
				ON ts2.ts_id = pa.ao_ts_id   
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
			LEFT JOIN Manufactory.EANCode e
				ON e.pants_id = pants.pants_id   
			OUTER APPLY (
			      	SELECT	';' + CAST(pac.percnt AS VARCHAR(900)) + '% ' + CAST(c.consist_name AS VARCHAR(900))
			      	FROM	Products.ProdArticleConsist pac   
			      			INNER JOIN	Products.Consist c
			      				ON	c.consist_id = pac.consist_id
			      	WHERE	pac.pa_id = pa.pa_id
			      	FOR XML	PATH('')
			      ) cons(x)OUTER APPLY (
			                     	SELECT	';' + CAST(col.color_name AS VARCHAR(900))
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
			                                      	SELECT	';' + CAST(c.contents_name AS VARCHAR(900))
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
			INNER JOIN	Products.TNVED t
				ON	t.tnved_id = tnvds.tnved_id
				ON	tnvds.subject_id = s.subject_id
				AND	tnvds.ct_id = s.ct_id
				AND	tnvds.consist_type_id = oa_ct.consist_type_id
				