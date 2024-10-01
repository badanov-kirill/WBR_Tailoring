CREATE PROCEDURE [Manufactory].[ChestnyZnakInCirculationDetail_GetFor]
@fabricator_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	'01' + oczdi.gtin01 + '21' + oczdi.serial21 cz,
			t.tnved_cod,
			CASE 
			     WHEN oad.declaration_type_id = 2 THEN 'CONFORMITY_CERTIFICATE'
			     WHEN oad.declaration_type_id = 1 THEN 'CONFORMITY_DECLARATION'
			END         sertificate_type,
			oad.declaration_number sertificate_num,
			CAST(oad.start_date AS DATETIME) sertificate_dt,
			CAST(puc.packing_dt AS DATETIME) packing_dt
	FROM	Manufactory.OrderChestnyZnakDetailItem oczdi   
			LEFT JOIN	Manufactory.OrderChestnyZnakDetail oczd
				ON	oczd.oczd_id = oczdi.oczd_id 
			LEFT JOIN Manufactory.OrderChestnyZnak AS ocz ON ocz.ocz_id = oczd.ocz_id  
			LEFT JOIN	Planing.SketchPlanColorVariantTS spcvt
				ON	spcvt.spcvts_id = oczd.spcvts_id   
			LEFT JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.spcv_id = spcvt.spcv_id   
			LEFT JOIN	Products.ProdArticleNomenclature pan
				ON	pan.pan_id = spcv.pan_id   
			LEFT JOIN	Products.ProdArticle pa
				ON	pa.pa_id = pan.pa_id   
			LEFT JOIN	Products.Sketch s
				ON	s.sketch_id = pa.sketch_id   
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
			--OUTER APPLY (
			--      	SELECT	TOP(1) sert.sertificate_type,
			--      			sert.sertificate_num,
			--      			sert.sertificate_dt
			--      	FROM	Products.Sertificates sert   
			--      			INNER JOIN	Products.Sertificates_TNVD st
			--      				ON	st.sertificate_id = sert.sertificate_id
			--      	WHERE	st.tnvd_cod = LEFT(t.tnved_cod, 4)
			--      	ORDER BY
			--      		sert.finish_dt DESC
			--      )     oas
			OUTER apply (
				SELECT TOP(1) sd.declaration_number
					,sd.start_date
					,sd.end_date
					,sd.declaration_type_id
				from Settings.Declarations_TNVED dt
				inner join Settings.Declarations sd
					ON sd.declaration_id = dt.declaration_id
					AND ocz.create_dt between sd.start_date and sd.end_date
				inner join Settings.Declaration_Fabricators df
					ON df.declaration_id = sd.declaration_id
				WHERE dt.tnved_id = t.tnved_id
					AND ocz.fabricator_id = df.fabricator_id 
				ORDER BY sd.declaration_type_id, sd.end_date desc
			)oad
					
			INNER JOIN Manufactory.ProductUnicCode_ChestnyZnakItem pucczi
				ON pucczi.oczdi_id = oczdi.oczdi_id
			LEFT JOIN Manufactory.ProductUnicCode puc
				ON puc.product_unic_code = pucczi.product_unic_code
	WHERE	oczdi.oczd_id IS NOT NULL
			AND ocz.fabricator_id = @fabricator_id
			AND	NOT EXISTS (
			   		SELECT	1
			   		FROM	Manufactory.ChestnyZnakInCirculationDetail czicd
			   		WHERE	czicd.oczdi_id = oczdi.oczdi_id
			   	)