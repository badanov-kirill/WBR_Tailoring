CREATE PROCEDURE [Manufactory].[ChestnyZnakInCirculationDetail_Get]
	@czic_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	'01' + oczdi.gtin01 + '21' + oczdi.serial21 cz,
			t.tnved_cod,
			CASE 
			     WHEN oas.sertificate_type = 'C' THEN 'CONFORMITY_CERTIFICATE'
			     WHEN oas.sertificate_type = 'D' THEN 'CONFORMITY_DECLARATION'
			END         sertificate_type,
			oas.sertificate_num,
			CAST(oas.sertificate_dt AS DATETIME) sertificate_dt,
			CAST(puc.packing_dt AS DATETIME) packing_dt
	FROM	Manufactory.ChestnyZnakInCirculationDetail czicd   
			INNER JOIN	Manufactory.OrderChestnyZnakDetailItem oczdi
				ON	oczdi.oczdi_id = czicd.oczdi_id   
			LEFT JOIN	Manufactory.OrderChestnyZnakDetail oczd
				ON	oczd.oczd_id = oczdi.oczd_id   
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
			LEFT JOIN	products.TNVED t
				ON	t.tnved_id = tnvds.tnved_id   
			OUTER APPLY (
			      	SELECT	TOP(1) sert.sertificate_type,
			      			sert.sertificate_num,
			      			sert.sertificate_dt
			      	FROM	Products.Sertificates sert   
			      			INNER JOIN	Products.Sertificates_TNVD st
			      				ON	st.sertificate_id = sert.sertificate_id
			      	WHERE	st.tnvd_cod = LEFT(t.tnved_cod, 4)
			      	ORDER BY
			      		sert.finish_dt DESC
			      )     oas
			LEFT JOIN Manufactory.ProductUnicCode_ChestnyZnakItem pucczi
				ON pucczi.oczdi_id = oczdi.oczdi_id
			LEFT JOIN Manufactory.ProductUnicCode puc
				ON puc.product_unic_code = pucczi.product_unic_code
	WHERE	czicd.czic_id = @czic_id