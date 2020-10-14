CREATE PROCEDURE [Planing].[SketchPlanColorVariant_ForCutting]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	DECLARE @cv_status_placing TINYINT = 12 --Назначен в цех
	
	SELECT	spcv.spcv_id,
			sp.sketch_id,
			ISNULL(s.imt_name, s2.subject_name_sf) imt_name,
			an.art_name,
			pa.sa + pan.sa     sa,
			spcv.spcv_name,
			spcv.sew_office_id,
			os.office_name     sew_office_name,
			oa.shkrm_id,
			oa.office_id,
			oa.office_name,
			spcv.corrected_qty,
			CAST(spcv.sew_deadline_dt AS DATETIME) sew_deadline_dt
	FROM	Planing.SketchPlanColorVariant spcv   
			INNER JOIN	Planing.SketchPlan sp
				ON	sp.sp_id = spcv.sp_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = sp.sketch_id   
			INNER JOIN	Products.[Subject] s2
				ON	s2.subject_id = s.subject_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id   
			INNER JOIN	Products.ProdArticleNomenclature pan
				ON	pan.pan_id = spcv.pan_id   
			INNER JOIN	Products.ProdArticle pa
				ON	pa.pa_id = pan.pa_id   
			INNER JOIN	Settings.OfficeSetting os
				ON	os.office_id = spcv.sew_office_id   
			OUTER APPLY (
			      	SELECT	TOP(1) smr.shkrm_id,
			      			os2.office_id,
			      			os2.office_name
			      	FROM	Planing.SketchPlanColorVariantCompleting spcvc   
			      			LEFT JOIN	Warehouse.SHKRawMaterialReserv smr   
			      			INNER JOIN	Warehouse.SHKRawMaterialOnPlace smop
			      				ON	smop.shkrm_id = smr.shkrm_id   
			      			INNER JOIN	Warehouse.StoragePlace stpl
			      				ON	stpl.place_id = smop.place_id   
			      			INNER JOIN	Warehouse.ZoneOfResponse zor
			      				ON	zor.zor_id = stpl.zor_id   
			      			INNER JOIN	Settings.OfficeSetting os2
			      				ON	zor.office_id = os2.office_id
			      				ON	smr.spcvc_id = spcvc.spcvc_id
			      	WHERE	spcvc.spcv_id = spcv.spcv_id
			      	ORDER BY
			      		CASE 
			      		     WHEN smr.spcvc_id IS NULL THEN 0
			      		     WHEN zor.office_id != spcv.sew_office_id THEN 1
			      		     ELSE 3
			      		END ASC
			      )            oa
	WHERE	spcv.is_deleted = 0
			AND	spcv.cvs_id IN (@cv_status_placing)
			AND	spcv.sew_office_id IS NOT NULL
	ORDER BY an.art_name
