CREATE PROCEDURE [Planing].[SketchPlanColorVariant_GetForConfectionMap]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	DECLARE @cv_status_layout_close TINYINT = 8 --Раскладка привязана
	DECLARE @spcv_tab TABLE(spcv_id INT, tl_id INT)
	
	INSERT INTO @spcv_tab
	  (
	    spcv_id,
	    tl_id
	  )
	SELECT	spcv.spcv_id,
			oa.tl_id
	FROM	Planing.SketchPlanColorVariant spcv   
			OUTER APPLY (
			      	SELECT	TOP(1) tl.tl_id
			      	FROM	Manufactory.TaskLayout tl
			      	WHERE	tl.spcv_id = spcv.spcv_id
			      	ORDER BY
			      		tl.tl_id DESC
			      ) oa
	WHERE	spcv.cvs_id = @cv_status_layout_close
			AND	spcv.is_deleted = 0
			AND	spcv.pan_id IS NOT NULL
	
	SELECT	spcv.spcv_id,
			st.tl_id,
			s.sketch_id,
			an.art_name,
			ISNULL(s.imt_name, sj.subject_name) imt_name,
			pa.sa + pan.sa sa
	FROM	@spcv_tab st   
			INNER JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.spcv_id = st.spcv_id   
			INNER JOIN	Planing.SketchPlan sp
				ON	sp.sp_id = spcv.sp_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = sp.sp_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id   
			INNER JOIN	Products.[Subject] sj
				ON	sj.subject_id = s.subject_id   
			INNER JOIN	Products.ProdArticleNomenclature pan
				ON	pan.pan_id = spcv.pan_id   
			INNER JOIN	Products.ProdArticle pa
				ON	pa.pa_id = pan.pa_id
	
	SELECT	DISTINCT st.spcv_id,
			st.tl_id,
			s.sketch_id,
			an.art_name,
			ISNULL(s.imt_name, sj.subject_name) imt_name,
			s.sa
	FROM	@spcv_tab st   
			INNER JOIN	Manufactory.TaskLayoutDetail tld
				ON	st.tl_id = tld.tl_id   
			INNER JOIN	Manufactory.Layout l
				ON	l.layout_id = tld.layout_id   
			INNER JOIN	Manufactory.LayoutAddedSketch las
				ON	las.layout_id = l.layout_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = las.sketch_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id   
			INNER JOIN	Products.[Subject] sj
				ON	sj.subject_id = s.subject_id