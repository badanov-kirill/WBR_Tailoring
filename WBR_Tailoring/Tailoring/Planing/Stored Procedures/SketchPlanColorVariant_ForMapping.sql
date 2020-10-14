CREATE PROCEDURE [Planing].[SketchPlanColorVariant_ForMapping]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	DECLARE @completing_up INT = 4
	DECLARE @cv_status_ready TINYINT = 2 --Цветовариант готов к отшиву
	DECLARE @cv_status_sel_pasp_ready TINYINT = 4 --Подготовлены паспорта материалов
	DECLARE @cv_status_corr_reserv TINYINT = 5 --На изменение резервов
	DECLARE @cv_status_pasp_get TINYINT = 6 --Паспорта получены
	DECLARE @cv_status_to_layout TINYINT = 7 --Отправлен на раскладку
	DECLARE @cv_status_layout_close TINYINT = 8 --Раскладка привязана
	DECLARE @cv_status_add_as_compain TINYINT = 11 --Создан как компаньен
	
	SELECT	spcv.spcv_id,
			sp.sketch_id,
			ISNULL(s.imt_name, s2.subject_name_sf) imt_name,
			an.art_name,
			s.sa,
			s.sa_local,
			s.constructor_employee_id,
			spcv.spcv_name,
			oa.color_id,
			oa.color_name,
			oa.rmt_name,
			sp.comment       sp_comment,
			spcv.comment     cv_comment,
			oa.comment       detail_comment
	FROM	Planing.SketchPlanColorVariant spcv   
			INNER JOIN	Planing.SketchPlan sp
				ON	sp.sp_id = spcv.sp_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = sp.sketch_id   
			INNER JOIN	Products.[Subject] s2
				ON	s2.subject_id = s.subject_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id   
			OUTER APPLY (
			      	SELECT	TOP(1) spcvc.color_id,
			      			cc.color_name,
			      			rmt.rmt_name,
			      			spcvc.comment
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
			      )          oa
	WHERE	spcv.is_deleted = 0
			AND	spcv.cvs_id IN (@cv_status_ready, @cv_status_sel_pasp_ready, @cv_status_corr_reserv, @cv_status_corr_reserv, @cv_status_pasp_get, @cv_status_to_layout, @cv_status_layout_close)
			AND	spcv.pan_id IS NULL
	UNION ALL
	SELECT	spcv.spcv_id,
			sp.sketch_id,
			ISNULL(s.imt_name, s2.subject_name_sf) imt_name,
			an.art_name,
			s.sa,
			s.sa_local,
			s.constructor_employee_id,
			spcv.spcv_name,
			oa.color_id,
			oa.color_name,
			oa.rmt_name,
			'Базовый предмет ' + ISNULL(s.imt_name, s2.subject_name_sf) + '(' + anb.art_name + ') ' sp_comment,
			'Базовый артикул ' + sb.sa     cv_comment,
			''                             detail_comment
	FROM	Planing.SketchPlanColorVariant spcv   
			INNER JOIN	Planing.AddedSketchPlanMapping aspm
				ON	aspm.linked_spcv_id = spcv.spcv_id   
			INNER JOIN	Planing.SketchPlanColorVariant spcvb
				ON	spcvb.spcv_id = aspm.base_spcv_id   
			INNER JOIN	Planing.SketchPlan sp
				ON	sp.sp_id = spcv.sp_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = sp.sketch_id   
			INNER JOIN	Products.[Subject] s2
				ON	s2.subject_id = s.subject_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id   
			INNER JOIN	Planing.SketchPlan spb
				ON	spb.sp_id = spcvb.sp_id   
			INNER JOIN	Products.Sketch sb
				ON	sb.sketch_id = spb.sketch_id   
			INNER JOIN	Products.[Subject] s2b
				ON	s2b.subject_id = sb.subject_id   
			INNER JOIN	Products.ArtName anb
				ON	anb.art_name_id = sb.art_name_id   
			OUTER APPLY (
			      	SELECT	TOP(1) spcvc.color_id,
			      			cc.color_name,
			      			rmt.rmt_name,
			      			spcvc.comment
			      	FROM	Planing.SketchPlanColorVariantCompleting spcvc   
			      			INNER JOIN	Material.RawMaterialType rmt
			      				ON	rmt.rmt_id = spcvc.rmt_id   
			      			INNER JOIN	Material.ClothColor cc
			      				ON	cc.color_id = spcvc.color_id
			      	WHERE	spcvc.spcv_id = spcvb.spcv_id
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
			      )                        oa
	WHERE	spcv.is_deleted = 0
			AND	spcv.cvs_id = @cv_status_add_as_compain
			AND	spcv.pan_id IS NULL
	ORDER BY an.art_name