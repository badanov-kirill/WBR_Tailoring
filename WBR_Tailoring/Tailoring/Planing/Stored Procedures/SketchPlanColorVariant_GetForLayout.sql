CREATE PROCEDURE [Planing].[SketchPlanColorVariant_GetForLayout]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	DECLARE @cv_status_to_layout TINYINT = 7 --Отправлен на раскладку
	
	SELECT	sp.sketch_id,
			ISNULL(s.imt_name, s2.subject_name_sf) imt_name,
			an.art_name,
			s.sa,
			s.sa_local
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
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id
	WHERE	spcv.is_deleted = 0
			AND	spcv.cvs_id = @cv_status_to_layout
	GROUP BY
		sp.sketch_id,
		ISNULL(s.imt_name, s2.subject_name_sf),
		an.art_name,
		s.sa,
		s.sa_local