CREATE PROCEDURE [Reports].[HistorySketchPlanColorVariant_GetBySPCV]
	@spcv_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	CAST(spcv.dt AS DATETIME) dt,
			spcv.employee_id,
			spcv.spcv_name,
			cvs.cvs_name,
			spcv.qty,
			spcv.is_deleted,
			spcv.comment       cv_comment,
			spcv.corrected_qty,
			spcv.pan_id,
			pa.sa + pan.sa     sa,
			os.office_name     sew_office_name,
			CAST(spcv.sew_deadline_dt AS DATETIME) sew_deadline_dt,
			spcv.cost_plan_year,
			spcv.cost_plan_month,
			spcv.spcv_id,
			sp.proc_name
	FROM	History.SketchPlanColorVariant spcv   
			INNER JOIN	Planing.ColorVariantStatus cvs
				ON	cvs.cvs_id = spcv.cvs_id   
			LEFT JOIN	Products.ProdArticleNomenclature pan   
			INNER JOIN	Products.ProdArticle pa
				ON	pa.pa_id = pan.pa_id
				ON	pan.pan_id = spcv.pan_id   
			LEFT JOIN	Settings.OfficeSetting os
				ON	os.office_id = spcv.sew_office_id
			INNER JOIN History.StoredProcedure sp
				ON sp.proc_id = spcv.proc_id
	WHERE	spcv.spcv_id = @spcv_id
	ORDER BY spcv.log_id
	