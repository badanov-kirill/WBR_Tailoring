CREATE PROCEDURE [Budget].[ProdArticleBudget_GetBySketch]
	@sketch_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	pa.pa_id,
			pab.pab_id,
			pabc.pabc_id,
			pabc.cloth_id,
			c.cloth_name,
			pabc.color_id,
			cc.color_name,
			pabc.prev_count_meters,
			pab.plan_count,
			pab.plan_year,
			pab.plan_month,
			pab.comment,
			sk.sa_local                 article,
			DATETIMEFROMPARTS(pab.plan_year, pab.plan_month, 1, 0, 0, 0, 0) plan_dt,
			pabc.comment                cloth_comment,
			CAST(pabc.rv AS BIGINT)     cloth_rv_bigint,
			bs.bs_name,
			bcs.bcs_name,
			pabc.variant,
			pabc.is_main_color,
			CAST(pab.rv AS BIGINT)      rv_bigint,
			pab.bs_id
	FROM	Products.ProdArticle pa   
			INNER JOIN	Products.Sketch sk
				ON	sk.sketch_id = pa.sketch_id   
			INNER JOIN	Products.[Season] s
				ON	s.season_id = pa.season_id   
			INNER JOIN	Products.Brand b
				ON	b.brand_id = pa.brand_id   
			INNER JOIN	Budget.ProdArticleBudget pab
				ON	pab.pa_id = pa.pa_id   
			INNER JOIN	Budget.BudgetStatus bs
				ON	bs.bs_id = pab.bs_id   
			LEFT JOIN	Budget.ProdArticleBudgetCloth pabc   
			INNER JOIN	Material.Cloth c
				ON	c.cloth_id = pabc.cloth_id   
			INNER JOIN	Material.ClothColor cc
				ON	cc.color_id = pabc.color_id   
			INNER JOIN	Budget.BudgetClothStatus bcs
				ON	bcs.bcs_id = pabc.bcs_id
				ON	pabc.pab_id = pab.pab_id
	WHERE	pa.sketch_id = @sketch_id
	AND pa.is_deleted = 0