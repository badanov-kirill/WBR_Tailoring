CREATE PROCEDURE [Planing].[SketchPlanColorVariant_GetForLayout_v2]
	@sketch_xml XML
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	DECLARE @sketch_tab TABLE (sketch_id INT)
	
	INSERT INTO @sketch_tab
		(
			sketch_id
		)
	SELECT	ml.value('@sid[1]', 'int')
	FROM	@sketch_xml.nodes('root/det')x(ml)
	
	DECLARE @cv_status_create TINYINT = 1 --Создан
	DECLARE @cv_status_ready TINYINT = 2 --Зарезервировано
	DECLARE @cv_status_sel_pasp TINYINT = 3 --Сбор паспортов на материал
	DECLARE @cv_status_sel_pasp_ready TINYINT = 4 --Подготовлены паспорта материалов
	DECLARE @cv_status_corr_reserv TINYINT = 5 --На изменение резервов
	DECLARE @cv_status_pasp_get TINYINT = 6 --Паспорта получены
	DECLARE @cv_status_to_layout TINYINT = 7 --Отправлен на раскладку
	DECLARE @cv_status_layout_close TINYINT = 8 --Раскладка привязана
	DECLARE @completing_up INT = 4
	
	SELECT	spcv.spcv_id,
			s.sketch_id,
			an.art_name,
			ISNULL(s.imt_name, sj.subject_name) imt_name,
			CASE 
			     WHEN spcv.pan_id IS NULL THEN s.sa
			     ELSE pa.sa + pan.sa
			END         sa,
			oa.color_name,
			oa.rmt_name,
			spcv.spcv_name
	FROM	Planing.SketchPlanColorVariant spcv   
			INNER JOIN	Planing.SketchPlan sp
				ON	sp.sp_id = spcv.sp_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = sp.sketch_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id   
			INNER JOIN	Products.[Subject] sj
				ON	sj.subject_id = s.subject_id   
			LEFT JOIN	Products.ProdArticleNomenclature pan
				ON	pan.pan_id = spcv.pan_id   
			LEFT JOIN	Products.ProdArticle pa
				ON	pa.pa_id = pan.pa_id   
			OUTER APPLY (
			      	SELECT	TOP(1) cc.color_name,
			      			rmt.rmt_name
			      	FROM	Planing.SketchPlanColorVariantCompleting spcvc   
			      			INNER JOIN	Material.RawMaterialType rmt
			      				ON	rmt.rmt_id = spcvc.rmt_id   
			      			INNER JOIN	Material.ClothColor cc
			      				ON	cc.color_id = spcvc.color_id
			      	WHERE	spcvc.spcv_id = spcv.spcv_id
			      	ORDER BY
			      		CASE 
			      		     WHEN spcvc.completing_id = @completing_up AND spcvc.completing_number = 1 THEN 0
			      		     ELSE 1
			      		END,
			      		CASE 
			      		     WHEN spcvc.comment IS NOT NULL THEN 0
			      		     ELSE 1
			      		END,
			      		spcvc.completing_number,
			      		spcvc.color_id     DESC,
			      		spcvc.spcvc_id     DESC
			      )     oa
	WHERE	spcv.is_deleted = 0
			AND	spcv.cvs_id IN (@cv_status_create, @cv_status_ready, @cv_status_sel_pasp, @cv_status_sel_pasp_ready, @cv_status_corr_reserv, @cv_status_pasp_get, 
			   	               @cv_status_to_layout, @cv_status_layout_close)
			AND	EXISTS (
			   		SELECT	1
			   		FROM	@sketch_tab st
			   		WHERE	st.sketch_id = sp.sketch_id
			   	)
	ORDER BY
		an.art_name	
