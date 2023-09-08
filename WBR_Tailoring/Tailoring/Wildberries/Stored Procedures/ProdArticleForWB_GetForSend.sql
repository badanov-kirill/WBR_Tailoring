CREATE PROCEDURE [Wildberries].[ProdArticleForWB_GetForSend]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	pafw.pa_id,
			CAST(pafw.dt AS DATETIME)     dt,
			b.brand_name,
			sj.subject_name,
			an.art_name,
			pa.sa,
			oasa.x                        sa_nms,
			pa.imt_id,
			ISNULL(oas.have_not_save, 0) have_not_save,
			pafw.fabricator_id,
			f.fabricator_name
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
			INNER JOIN	Settings.Fabricators f
				ON f.fabricator_id = pafw.fabricator_id
			OUTER APPLY (
			      	SELECT	pan.sa + ';'
			      	FROM	Products.ProdArticleNomenclature pan
			      	WHERE	pan.pa_id = pa.pa_id
			      	FOR XML	PATH('')
			      ) oasa(x)
			OUTER APPLY (
					SELECT TOP(1) 1 have_not_save 
					FROM 	Products.ProdArticleNomenclature pan2
			      	WHERE	pan2.pa_id = pa.pa_id
			      	AND pan2.nm_id IS NULL
			      	AND NOT EXISTS(
			              	SELECT	1
			              	FROM	Wildberries.ProdArticleNomenclatureForWB panfw
			              	WHERE	panfw.pan_id = pan2.pan_id AND panfw.fabricator_id = pafw.fabricator_id
							)
			)     oas  
			OUTER APPLY (
					SELECT TOP(1) 1 have_save					 
					FROM 	Products.ProdArticleNomenclature pan3
			      	WHERE	pan3.pa_id = pa.pa_id
			      	AND pan3.nm_id IS NOT NULL			      	
			)     oan  
	WHERE	pafw.send_dt IS NULL
			AND (ISNULL(oas.have_not_save, 0) = 1 OR (ISNULL(oas.have_not_save, 0) = 0 AND oan.have_save = 1))
			--AND	ISNULL(pafw.is_error, 0) = 0