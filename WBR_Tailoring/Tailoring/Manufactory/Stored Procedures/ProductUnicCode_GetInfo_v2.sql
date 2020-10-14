﻿CREATE PROCEDURE [Manufactory].[ProductUnicCode_GetInfo_v2]
	@product_unic_code INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	DECLARE @lining_ao_id INT = 4
	DECLARE @error_text VARCHAR(MAX)
	
	SELECT	@error_text = CASE 
	      	                   WHEN puc.product_unic_code IS NULL THEN 'Такого ШК ' + CAST(v.product_unic_code AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN puc.product_unic_code IS NOT NULL AND e.ean IS NULL AND tnvds.ts_id IS NULL THEN 'Для ШК ' + CAST(v.product_unic_code AS VARCHAR(10)) 
	      	                        + ' арт: ' + pa.sa + pan.sa + ' не удалось определить ТНВД. Обратесь к руководителю'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@product_unic_code))v(product_unic_code)   
			LEFT JOIN	Manufactory.ProductUnicCode puc   
			INNER JOIN	Products.ProdArticleNomenclatureTechSize pants
				ON	pants.pants_id = puc.pants_id   
			INNER JOIN	Products.ProdArticleNomenclature pan
				ON	pan.pan_id = pants.pan_id   
			INNER JOIN	Products.ProdArticle pa
				ON	pa.pa_id = pan.pa_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = pa.sketch_id
				ON	puc.product_unic_code = v.product_unic_code   
			LEFT JOIN	Manufactory.EANCode e
				ON	e.pants_id = puc.pants_id   
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
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		INSERT INTO Synchro.ProductsForEAN
			(
				pants_id
			)
		SELECT	pants2.pants_id
		FROM	Manufactory.ProductUnicCode puc   
				INNER JOIN	Products.ProdArticleNomenclatureTechSize pants
					ON	pants.pants_id = puc.pants_id   
				INNER JOIN	Products.ProdArticleNomenclatureTechSize pants2
					ON	pants2.pan_id = pants.pan_id   
				LEFT JOIN	Synchro.ProductsForEAN pfe
					ON	pfe.pants_id = pants2.pants_id
		WHERE	puc.product_unic_code = @product_unic_code
				AND	pfe.pants_id IS NULL
		
		SELECT	puc.product_unic_code,
				pants.pants_id,
				pa.sa + pan.sa              sa,
				ISNULL(s.imt_name, sj.subject_name_sf) imt_name,
				b.brand_name,
				ts.ts_name,
				puc.operation_id,
				o.operation_name,
				e.ean                       barcode,
				ISNULL(cr.color_name, 'безцветное') color_name,
				CAST(ISNULL(spcv.deadline_package_dt, DATEADD(DAY, -7, sp.plan_sew_dt)) AS DATETIME) plan_sew_dt,
				STUFF(oac.x, 1, 2, '') + CASE 
				                              WHEN oal.x IS NOT NULL THEN CHAR(10) + '  Подкладка: ' + STUFF(oal.x, 1, 2, '')
				                              ELSE ''
				                         END consists,
				STUFF(oact.x, 1, 1, '')     carething,
				os.organization_name + ' ' + CHAR(10) + os.label_address organization
		FROM	Manufactory.ProductUnicCode puc   
				LEFT JOIN	Manufactory.EANCode e
					ON	e.pants_id = puc.pants_id   
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
		WHERE	puc.product_unic_code = @product_unic_code
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
		    ROLLBACK TRANSACTION
		
		DECLARE @ErrNum INT = ERROR_NUMBER();
		DECLARE @estate INT = ERROR_STATE();
		DECLARE @esev INT = ERROR_SEVERITY();
		DECLARE @Line INT = ERROR_LINE();
		DECLARE @Mess VARCHAR(MAX) = CHAR(10) + ISNULL('Процедура: ' + ERROR_PROCEDURE(), '') 
		        + CHAR(10) + ERROR_MESSAGE();
		
		RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess) 
		WITH LOG;
	END CATCH
	