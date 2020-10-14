CREATE PROCEDURE [Planing].[SketchPlanColorVariant_GetForCorrectReserv]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	DECLARE @completing_up INT = 4
	DECLARE @cv_status_ready TINYINT = 2 --Цветовариант готов к отшиву
	
	DECLARE @cv_status_corr_reserv TINYINT = 5 --На изменение резервов
	
	SELECT	spcv.spcv_id,
			sp.sketch_id,
			ISNULL(s.imt_name, s2.subject_name_sf) imt_name,
			an.art_name,
			s.sa,
			s.sa_local,
			spcv.spcv_name,
			oa.color_id,
			oa.color_name,
			oa.rmt_name,
			spcv.qty
	FROM	Planing.SketchPlanColorVariant spcv   
			INNER JOIN	Planing.SketchPlan sp
				ON	sp.sp_id = spcv.sp_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = sp.sketch_id   
			INNER JOIN	Products.SketchStatus ss
				ON	ss.ss_id = s.ss_id   
			INNER JOIN	Products.SketchType st
				ON	st.st_id = s.st_id   
			INNER JOIN	Products.[Subject] s2
				ON	s2.subject_id = s.subject_id   
			LEFT JOIN	Products.ArtName an
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
			      ) oa
	WHERE	spcv.is_deleted = 0
			AND	spcv.cvs_id = @cv_status_corr_reserv