CREATE PROCEDURE [Ozon].[ProdArticleForOzon_GetForSend]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	pafo.pa_id,
			CAST(pafo.dt AS DATETIME)     dt,
			b.brand_name,
			sj.subject_name,
			an.art_name,
			pa.sa,
			oasa.x                        sa_nms,
			pa.imt_id
	FROM	Ozon.ProdArticleForOZON pafo   
			INNER JOIN	Products.ProdArticle pa
				ON	pa.pa_id = pafo.pa_id   
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
	WHERE	pafo.send_dt IS NULL 