CREATE PROCEDURE [Logistics].[TransferBoxSpecialSPCV_Get]
	@transfer_box_id BIGINT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	s.sketch_id,
			an.art_name,
			ISNULL(s.imt_name, sj.subject_name_sf) imt_name,
			b.brand_name,
			spcv.spcv_id,
			pa.sa + pan.sa     nm_sa,
			c.color_name       main_color,
			os.office_name     sew_office_name,
			spcv.sew_office_id,
			CAST(spcv.deadline_package_dt AS DATETIME) deadline_package_dt,
			spcvc.cutting_qty,
			spcvc.finished
	FROM	Logistics.TransferBoxSpecialSPCV tbss   
			INNER JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.spcv_id = tbss.spcv_id   
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
	WHERE	tbss.transfer_box_id = @transfer_box_id