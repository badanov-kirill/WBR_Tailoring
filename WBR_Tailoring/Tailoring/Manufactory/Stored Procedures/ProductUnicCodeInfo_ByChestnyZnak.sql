CREATE PROCEDURE [Manufactory].[ProductUnicCodeInfo_ByChestnyZnak]
	@gtin VARCHAR(14),
	@serial VARCHAR(20)
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	DECLARE @lining_ao_id INT = 4
	
	SELECT	puc.product_unic_code,
			pants.pants_id,
			pa.sa + pan.sa                   sa,
			ISNULL(s.imt_name, sj.subject_name_sf) imt_name,
			b.brand_name,
			ts.ts_name,
			puc.operation_id,
			o.operation_name,
			e.ean                            barcode,
			ISNULL(cr.color_name, 'безцветное') color_name,
			CAST(ISNULL(spcv.deadline_package_dt, DATEADD(DAY, -7, sp.plan_sew_dt)) AS DATETIME) plan_sew_dt,
			STUFF(oac.x, 1, 2, '') + CASE 
			                              WHEN oal.x IS NOT NULL THEN CHAR(10) + '  Подкладка: ' + STUFF(oal.x, 1, 2, '')
			                              ELSE ''
			                         END     consists,
			STUFF(oact.x, 1, 1, '')          carething,
			os.organization_name + ' ' + CHAR(10) + os.label_address organization,
			oczdi.gtin01,
			oczdi.serial21,
			oczdi.intrnal91,
			oczdi.intrnal92,
			oczdi.oczdi_id
	FROM	Manufactory.OrderChestnyZnakDetailItem oczdi   
			INNER JOIN	Manufactory.ProductUnicCode_ChestnyZnakItem pucczi
				ON pucczi.oczdi_id = oczdi.oczdi_id   
			INNER JOIN	Manufactory.ProductUnicCode puc
				ON	puc.product_unic_code = pucczi.product_unic_code 			  
			INNER JOIN	Products.ProdArticleNomenclatureTechSize pants
				ON	pants.pants_id = puc.pants_id   
			INNER JOIN	Products.ProdArticleNomenclature pan
				ON	pan.pan_id = pants.pan_id   
			INNER JOIN	Products.ProdArticle pa
				ON	pa.pa_id = pan.pa_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = pa.sketch_id   
			INNER JOIN	Products.[Subject] sj
				ON	sj.subject_id = s.subject_id   
			INNER JOIN	Products.Brand b
				ON	b.brand_id = pa.brand_id   
			INNER JOIN	Products.TechSize ts
				ON	ts.ts_id = pants.ts_id   
			INNER JOIN	Manufactory.Operation o
				ON	o.operation_id = puc.operation_id   
			LEFT JOIN	Products.ProdArticleNomenclatureColor panc   
			INNER JOIN	Products.Color cr
				ON	cr.color_cod = panc.color_cod
				ON	panc.pan_id = pan.pan_id
				AND	panc.is_main = 1   
			LEFT JOIN	Manufactory.Cutting c
				ON	c.cutting_id = puc.cutting_id   
			LEFT JOIN	Planing.SketchPlanColorVariantTS spcvt   
			INNER JOIN	Planing.SketchPlanColorVariant spcv   
			INNER JOIN	Planing.SketchPlan sp
				ON	sp.sp_id = spcv.sp_id
				ON	spcv.spcv_id = spcvt.spcv_id
				ON	spcvt.spcvts_id = c.spcvts_id   
			LEFT JOIN	Settings.OfficeSetting os
				ON	(spcv.sew_office_id IS NOT NULL
				AND	os.office_id = spcv.sew_office_id)
				OR	(spcv.sew_office_id IS NULL
				AND	os.is_main_wh = 1)  
			LEFT JOIN	Manufactory.EANCode e
				ON	e.pants_id = puc.pants_id 	
				 AND e.fabricator_id = spcv.sew_fabricator_id
			OUTER APPLY (
			      	SELECT	', ' + c.consist_name + ' ' + CASE 
			      	      	                                   WHEN ISNULL(pac.percnt, 0) = 0 THEN ''
			      	      	                                   ELSE CAST(pac.percnt AS VARCHAR(10)) + '%'
			      	      	                              END
			      	FROM	Products.ProdArticleConsist pac   
			      			INNER JOIN	Products.Consist AS c
			      				ON	c.consist_id = pac.consist_id
			      	WHERE	pac.pa_id = pa.pa_id
			      	FOR XML	PATH('')
			      ) oac(x)OUTER APPLY (
			                    	SELECT	', ' + ao.ao_name + ' ' + CASE 
			                    	      	                               WHEN ISNULL(paao.ao_value, 0) = 0 THEN ''
			                    	      	                               ELSE CAST(CAST(paao.ao_value AS INT) AS VARCHAR(10)) + '%'
			                    	      	                          END
			                    	FROM	Products.ProdArticleAddedOption paao   
			                    			INNER JOIN	Products.AddedOption AS ao
			                    				ON	ao.ao_id = paao.ao_id
			                    	WHERE	paao.pa_id = pa.pa_id
			                    			AND	ao.ao_id_parent = @lining_ao_id
			                    			AND	ao.ao_id != 26
			                    	FOR XML	PATH('')
			                    )oal(x)OUTER APPLY (
			                                 	SELECT	';' + ctao.img_name
			                                 	FROM	Products.ProdArticleAddedOption paao   
			                                 			INNER JOIN	Products.AddedOption AS ao
			                                 				ON	ao.ao_id = paao.ao_id   
			                                 			INNER JOIN	Products.CareThingAddedOption ctao
			                                 				ON	ctao.ao_id = ao.ao_id
			                                 	WHERE	paao.pa_id = pa.pa_id
			                                 	FOR XML	PATH('')
			                                 ) oact(x)
	WHERE	oczdi.gtin01 = @gtin
			AND	oczdi.serial21 = @serial
