CREATE PROCEDURE [Planing].[SketchPlanColorVariantTS_Get]
	@spcv_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	;
	WITH cte_pa AS (
		SELECT	pants.ts_id,
				ts.ts_name
		FROM	Planing.SketchPlanColorVariant spcv   
				INNER JOIN	Products.ProdArticleNomenclature pan
					ON	pan.pan_id = spcv.pan_id   
				INNER JOIN	Products.ProdArticleNomenclatureTechSize pants
					ON	pants.pan_id = pan.pan_id   
				INNER JOIN	Products.TechSize ts
					ON	ts.ts_id = pants.ts_id
		WHERE	spcv.spcv_id = @spcv_id
		AND pants.is_deleted = 0
	),cte_sp AS (
		SELECT	spcvt.ts_id,
				ts.ts_name,
				spcvt.cnt
		FROM	Planing.SketchPlanColorVariantTS spcvt   
				INNER JOIN	Products.TechSize ts
					ON	ts.ts_id = spcvt.ts_id
		WHERE	spcvt.spcv_id = @spcv_id
	)
	SELECT	ISNULL(sp.ts_id, pa.ts_id) ts_id,
			ISNULL(sp.ts_name, pa.ts_name) ts_name,
			ISNULL(sp.cnt, 0) cnt
	FROM	cte_sp sp   
			FULL JOIN	cte_pa pa
				ON	sp.ts_id = pa.ts_id
	ORDER BY ISNULL(sp.ts_name, pa.ts_name)