CREATE PROCEDURE [Logistics].[SPCVForTransferBoxSpecial]
	@office_id INT = NULL,
	@art_name VARCHAR(100) = NULL,
	@is_no_box BIT = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	DECLARE @dt DATE = GETDATE()
	
	SELECT	s.sketch_id,
			an.art_name,
			ISNULL(s.imt_name, sj.subject_name_sf) imt_name,
			b.brand_name,
			spcv.spcv_id,
			pa.sa + pan.sa             nm_sa,
			c.color_name               main_color,
			os.office_name             sew_office_name,
			spcv.sew_office_id,
			CAST(spcv.deadline_package_dt AS DATETIME) deadline_package_dt,
			ISNULL(oa_c.x, '') + ISNULL(spcv.comment, '') comment,
			spcvc.cutting_qty,
			spcvc.finished,
			ISNULL(oa_b.is_box, 0)     is_box
	FROM	Planing.SketchPlanColorVariant spcv   
			INNER JOIN	Planing.SketchPlanColorVariantCounter spcvc
				ON	spcvc.spcv_id = spcv.spcv_id   
			INNER JOIN	Products.ProdArticleNomenclature pan   
			INNER JOIN	Products.ProdArticle pa
				ON	pa.pa_id = pan.pa_id   
			LEFT JOIN	Products.ProdArticleNomenclatureColor panc   
			INNER JOIN	Products.Color c
				ON	c.color_cod = panc.color_cod
				ON	panc.pan_id = pan.pan_id
				AND	panc.is_main = 1   
			INNER JOIN	Products.Sketch s   
			LEFT JOIN	Products.ProductType pt
				ON	pt.pt_id = s.pt_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id   
			INNER JOIN	Products.[Subject] sj
				ON	sj.subject_id = s.subject_id   
			INNER JOIN	Products.Brand b
				ON	b.brand_id = s.brand_id
				ON	s.sketch_id = pa.sketch_id
				ON	pan.pan_id = spcv.pan_id   
			LEFT JOIN	Settings.OfficeSetting os
				ON	os.office_id = spcv.sew_office_id   
			OUTER APPLY (
			      	SELECT	spcvc.comment + ' | '
			      	FROM	Planing.SketchPlanColorVariantComment spcvc
			      	WHERE	spcvc.spcv_id = spcv.spcv_id
			      	FOR XML	PATH('')
			      ) oa_c(x)OUTER APPLY (
			                     	SELECT	TOP(1) 1 is_box
			                     	FROM	Logistics.TransferBoxSpecialSPCV tbss
			                     	WHERE	tbss.spcv_id = spcv.spcv_id
			                     )     oa_b
	WHERE	(
	     		spcv.deadline_package_dt < @dt
	     		AND spcvc.dt_close IS NULL
	     		AND (@office_id IS NULL OR spcv.sew_office_id = @office_id)
	     		AND (@is_no_box IS NULL OR (@is_no_box = 1 AND oa_b.is_box IS NULL) OR (@is_no_box = 0 AND oa_b.is_box IS NOT NULL))
	     		AND @art_name IS NULL
	     	)
			OR	(an.art_name = @art_name AND spcv.deadline_package_dt IS NOT NULL)
	ORDER BY
		spcv.deadline_package_dt,
		spcv.sp_id,
		spcvc.spcv_id