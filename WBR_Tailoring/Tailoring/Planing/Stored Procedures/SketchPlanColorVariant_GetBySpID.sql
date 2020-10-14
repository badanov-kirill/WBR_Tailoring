CREATE PROCEDURE [Planing].[SketchPlanColorVariant_GetBySpID]
	@sp_id INT
AS
	SET NOCOUNT ON 
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @completing_up INT = 4
	
	SELECT	spcv.spcv_name,
			spcv.spcv_id,
			spcv.comment                  cv_comment,
			ISNULL(spcv.corrected_qty, spcv.qty) cv_qty,
			CAST(spcv.dt AS DATETIME)     spcv_dt,
			oa.color_name,
			pa.sa + pan.sa     nm_sa,
			cvs.cvs_name			
	FROM	Planing.SketchPlan sp     
			INNER JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.sp_id = sp.sp_id
			LEFT JOIN	Products.ProdArticleNomenclature pan   
			INNER JOIN	Products.ProdArticle pa
				ON	pa.pa_id = pan.pa_id
				ON	pan.pan_id = spcv.pan_id
			INNER JOIN Planing.ColorVariantStatus cvs
				ON cvs.cvs_id = spcv.cvs_id 
			OUTER APPLY (
	      			SELECT	TOP(1) cc.color_name
	      			FROM	Planing.SketchPlanColorVariantCompleting spcvc    
	      					INNER JOIN	Material.ClothColor cc
	      						ON	cc.color_id = spcvc.color_id
	      			WHERE	spcvc.spcv_id = spcv.spcv_id
	      			ORDER BY
	      				CASE 
	      					 WHEN spcvc.completing_id = @completing_up AND spcvc.completing_number = 1 THEN 0
	      					 ELSE 1
	      				END,
	      				spcvc.completing_number,
	      				spcvc.color_id     DESC,
	      				spcvc.spcvc_id     DESC
				  )                    oa
	WHERE	spcv.sp_id = @sp_id
			AND	spcv.is_deleted = 0
	ORDER BY
		spcv.spcv_id