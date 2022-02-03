CREATE PROCEDURE [Ozon].[ProdArticleForOzon_GetForSend]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	panfo.pan_id,
			pan.pa_id,
			CAST(panfo.dt AS DATETIME)     dt,
			b.brand_name,
			sj.subject_name,
			an.art_name,
			pa.sa,
			pa.sa + pan.sa                 sa_nms
	FROM	Ozon.ProdArticleNomenclatureForOZON panfo   
			INNER JOIN	Products.ProdArticleNomenclature pan
				ON	pan.pan_id = panfo.pan_id   
			INNER JOIN	Products.ProdArticle pa
				ON	pa.pa_id = pan.pa_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = pa.sketch_id   
			INNER JOIN	Products.Brand b
				ON	b.brand_id = pa.brand_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id   
			INNER JOIN	Products.[Subject] sj
				ON	sj.subject_id = s.subject_id
	WHERE	panfo.send_dt IS NULL
			AND	panfo.is_deleted = 0