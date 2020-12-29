CREATE PROCEDURE [Products].[ProdArticleForLamoda_BySFP]
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
           'ООО "Василиса"' [Наименование_изготовителя],	
           '109382, Россия, г. Москва, Егорьевский проезд, д3жc8' [Юридический_адрес_изготовителя],	
           '' [Наименование_импортера],	
           '' [Юридический_адрес_импортера],	
           '' [Наименование_дистрибьютора],	
           '' [Юридический_адрес_дистрибьютора],	
           'SH_W_RUS_2' [Размерная_шкала],	
           'RUS' [Система_размеров],	
           c.collection_name [Коллекция],	
           sj.subject_name [Тип_продукта_новый],	
           s.descr [Описание],	
           k.kind_name [Пол],	
           sn.season_name [Сезон],	
           '' [Гарантийный_период],
           '' [Срок_годности],	
           '' [Срок_эксплуатации],	
           STUFF(artcol.x, 1, 1, '') [Цвет],	
           '' [Укажите_стиль_товара_Вы_можете_выбрать_несколько_стилей_из_выпадающего_списка],	
           STUFF(cons.x, 1, 1, '')  [Состав_изделия],	
           '' [Тип_ткани],	
           '' [Вид_и_массовая_доля_натурального_и_химического_сырья],	
           '' [Состав_подкладки],	
           '' [Состав_утеплителя],	
           '' [Узор],	
           '' [Основная_категория],	
           '' [Инструкция_по_уходу],	
           '' [Необходимость_в_предварительной_стирке],	
           '' [Детали_одежды],	
           STUFF(con.x, 1, 1, '') [Комплектация],	
           '' [TrouserStyle],	
           '' [Длина_для_верхней_одежды],	
           '' [Длина],	
           '' [Длина_рукава_см],	
           '' [Тип_рукава],	
           '' [Длина_внешнего_шва],	
           '' [Длина_по_внутреннему_шву],	
           '' [Обхват_талии],	
           '' [Параметры_модели],	
           ts2.ts_name [Размер_изделия_на_модели],	
           '' [Рост_модели],	
           '' [Посадка_Талия],	
           '' [Укажите_фасон_джинс],	
           '' [Тип_застежки],	
           '' [Дополнительные_категории],	
           ISNULL(t.tnved_cod, '6104420000') [ТН_ВЭД],
           1 [EAC],	
           0 [Отправить_на_фотостудию],	
           dt.barcode [ProductId],	
           pan.price_ru [Цена],	
           '' [Цена_со_скидкой],	
           '' [ДатаНачалаСкидки],	
           '' [ДатаОкончанияСкидки],	
           ts.ts_name [Размер],	
           pa.sa + pan.sa [ParentSku],	
           dt.cnt [Количество],	
           pa.sa + pan.sa + '|' + ts.ts_name [SellerSku],	
           'Fulfillment by Lamoda' [ShipmentType],	
           '' [MainImage],
           '' [Image2],	
           '' [Image3],	
           '' [Image4],	
           '' [Image5],	
           '' [Image6],	
           '' [Image7],	
           '' [Image8]
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