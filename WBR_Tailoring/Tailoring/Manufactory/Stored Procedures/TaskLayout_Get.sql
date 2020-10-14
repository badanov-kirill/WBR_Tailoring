CREATE PROCEDURE [Manufactory].[TaskLayout_Get]
	@sketch_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	DECLARE @tl_status_create TINYINT = 1 --Создано
	
	SELECT	tl.tl_id,
			CAST(tl.create_dt AS DATETIME) create_dt,
			tl.create_employee_id,
			tl.tls_id,
			tls.tls_name,
			pa.sa + pan.sa sa
	FROM	Manufactory.TaskLayout tl   
			INNER JOIN	Manufactory.TaskLayoutStatus tls
				ON	tls.tls_id = tl.tls_id   
			INNER JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.spcv_id = tl.spcv_id   
			INNER JOIN	Planing.SketchPlan sp
				ON	sp.sp_id = spcv.sp_id   
			LEFT JOIN	Products.ProdArticleNomenclature pan   
			INNER JOIN	Products.ProdArticle pa
				ON	pa.pa_id = pan.pa_id
				ON	pan.pan_id = spcv.pan_id
	WHERE	sp.sketch_id = @sketch_id
			AND	tl.tls_id = @tl_status_create
