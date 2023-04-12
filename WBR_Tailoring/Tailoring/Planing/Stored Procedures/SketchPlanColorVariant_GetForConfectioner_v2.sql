CREATE PROCEDURE [Planing].[SketchPlanColorVariant_GetForConfectioner_v2]
	@art_name VARCHAR(100)
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	DECLARE @completing_up INT = 4
	DECLARE @spcv_tab TABLE(spcv_id INT, tl_id INT)
	
	INSERT INTO @spcv_tab
		(
			spcv_id,
			tl_id
		)
	SELECT	spcv.spcv_id,
			oa.tl_id
	FROM	Planing.SketchPlanColorVariant spcv   
			INNER JOIN	Planing.SketchPlan sp
				ON	sp.sp_id = spcv.sp_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = sp.sketch_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id   
			OUTER APPLY (
			      	SELECT	TOP(1) tl.tl_id
			      	FROM	Manufactory.TaskLayout tl
			      	WHERE	tl.spcv_id = spcv.spcv_id
			      	ORDER BY
			      		tl.tl_id DESC
			      ) oa
	WHERE	an.art_name = @art_name
			AND	spcv.is_deleted = 0
	
	SELECT	spcv.spcv_id,
			st.tl_id,
			s.sketch_id,
			an.art_name,
			ISNULL(s.imt_name, sj.subject_name) imt_name,
			CASE 
			     WHEN spcv.pan_id IS NULL THEN s.sa
			     ELSE pa.sa + pan.sa
			END                sa,
			oa.color_id,
			oa.color_name,
			oa.rmt_name,
			spcv.qty,
			spcv.cvs_id,
			spcv.corrected_qty,
			s.create_employee_id,
			s.constructor_employee_id,
			pa.sa + pan.sa     sketch_sa,
			CAST(sp.create_dt AS DATETIME) create_dt,
			os.office_name     sew_office_name,
			spcv.sew_office_id,
			sp.sew_fabricator_id as fabricator_id,
			f.fabricator_name as fabricator_name
	FROM	@spcv_tab st   
			INNER JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.spcv_id = st.spcv_id   
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
			LEFT JOIN	Settings.OfficeSetting os
				ON	os.office_id = spcv.sew_office_id   
			LEFT JOIN	Settings.Fabricators f
				ON	f.fabricator_id = sp.sew_fabricator_id
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
			      )            oa
	ORDER BY
		an.art_name
	
	SELECT	DISTINCT spcv.spcv_id,
			st.tl_id,
			s.sketch_id,
			an.art_name,
			ISNULL(s.imt_name, sj.subject_name) imt_name,
			ISNULL(pa.sa + pan.sa, s.sa)     sa,
			st.spcv_id                       base_spcv_id,
			spcv.corrected_qty,
			s.create_employee_id,
			s.constructor_employee_id
	FROM	@spcv_tab st   
			INNER JOIN	Planing.AddedSketchPlanMapping aspm
				ON	st.spcv_id = aspm.base_spcv_id   
			INNER JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.spcv_id = aspm.linked_spcv_id   
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
	WHERE	spcv.is_deleted = 0