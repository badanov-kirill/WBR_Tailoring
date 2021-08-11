CREATE PROCEDURE [Wildberries].[ProdArticleForWB_GetSave]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT TOP(500)	pafw.pa_id,
			CAST(pafw.dt AS DATETIME)     dt,
			b.brand_name,
			sj.subject_name,
			an.art_name,
			pa.sa,
			oasa.x                        sa_nms,
			CAST(pafw.send_dt AS DATETIME) send_dt,
			pa.imt_id,
			oaean.x eans,
			pa.sketch_id
	FROM	Wildberries.ProdArticleForWB pafw   
			INNER JOIN	Products.ProdArticle pa
				ON	pa.pa_id = pafw.pa_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = pa.sketch_id   
			INNER JOIN	Products.Brand b
				ON	b.brand_id = pa.brand_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id   
			INNER JOIN	Products.[Subject] sj
				ON	sj.subject_id = s.subject_id   
			OUTER APPLY (
			      	SELECT	pan.sa + ';'
			      	FROM	Products.ProdArticleNomenclature pan
			      	WHERE	pan.pa_id = pa.pa_id
			      	FOR XML	PATH('')
			      ) oasa(x)
			OUTER APPLY (
			      	SELECT e.ean + ';'
			      	FROM	Products.ProdArticleNomenclature pan
			      	INNER JOIN Products.ProdArticleNomenclatureTechSize pants ON pants.pan_id = pan.pan_id
			      	INNER JOIN Manufactory.EANCode e ON e.pants_id = pants.pants_id
			      	WHERE	pan.pa_id = pa.pa_id
			      	FOR XML	PATH('')
			      ) oaean(x)
	WHERE	pafw.send_dt IS NOT NULL
	ORDER BY
		pafw.send_dt DESC