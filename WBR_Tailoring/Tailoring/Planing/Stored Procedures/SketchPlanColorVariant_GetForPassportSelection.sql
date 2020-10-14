CREATE PROCEDURE [Planing].[SketchPlanColorVariant_GetForPassportSelection]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	DECLARE @cv_status_ready TINYINT = 2 --Цветовариант готов к отшиву
	DECLARE @cv_status_sel_pasp TINYINT = 3 --Сбор паспортов на материал
	DECLARE @cv_status_sel_pasp_ready TINYINT = 4 --Подготовлены паспорта материалов
	
	SELECT	spcv.spcv_id,
			sp.sketch_id,
			ISNULL(s.imt_name, s2.subject_name_sf) imt_name,
			an.art_name,
			s.sa,
			s.sa_local,
			spcv.spcv_name,
			b.brand_name
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
			INNER JOIN Products.Brand b ON b.brand_id = s.brand_id
	WHERE	spcv.is_deleted = 0
			AND	spcv.cvs_id IN (@cv_status_ready, @cv_status_sel_pasp, @cv_status_sel_pasp_ready)