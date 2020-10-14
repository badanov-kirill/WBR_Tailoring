CREATE PROCEDURE [Budget].[ProdArticleBudgetCloth_GetApprove]
	@brand_id INT = NULL,
	@office_id INT = NULL,
	@bsc_id INT = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	
	DECLARE @status_approve INT = 2
	DECLARE @status_complaint INT = 6
	
	SELECT	pabc.pabc_id,
			pabc.pab_id,
			pabc.cloth_id,
			c.cloth_name,
			pabc.color_id,
			cc.color_name,
			pabc.dt,
			pabc.bcs_id,
			bcs.bcs_name,
			pabc.comment,
			pabc.prev_count_meters,
			pabc.ordered_count_meters,
			pabc.actual_count_meters,
			CAST(pabc.rv AS BIGINT) rv_bigint
	INTO	#t
	FROM	Budget.ProdArticleBudgetCloth pabc   
			INNER JOIN	Budget.ProdArticleBudget pab
				ON	pab.pab_id = pabc.pab_id   
			INNER JOIN	Products.ProdArticle pa
				ON	pa.pa_id = pab.pa_id   
			INNER JOIN	Material.Cloth c
				ON	c.cloth_id = pabc.cloth_id   
			INNER JOIN	Material.ClothColor cc
				ON	cc.color_id = pabc.color_id   
			INNER JOIN	Budget.BudgetClothStatus bcs
				ON	bcs.bcs_id = pabc.bcs_id
	WHERE	pab.bs_id IN (@status_approve, @status_complaint)
			AND	(@brand_id IS NULL OR (pa.brand_id = @brand_id))
			AND	(@office_id IS NULL OR (pab.office_id = @office_id))
			AND	(@bsc_id IS NULL OR (pabc.bcs_id = @bsc_id))
	
	SELECT	pa.pa_id,
			sk.sketch_id,
			sk.model_year,
			an.art_name,
			sk.sa_local                article,
			pa.brand_id,
			b.brand_name,
			pa.season_id,
			s.season_name,
			pab.pab_id,
			pab.plan_count,
			pab.plan_year,
			pab.plan_month,
			pab.employee_id,
			pab.dt,
			pab.planing_employee_id,
			pab.planing_dt,
			pab.office_id,
			pab.comment,
			CAST(pab.rv AS BIGINT)     rv_bigint,
			pab.bs_id
	FROM	Budget.ProdArticleBudget pab   
			INNER JOIN	Products.ProdArticle pa
				ON	pa.pa_id = pab.pa_id   
			INNER JOIN	Products.Sketch sk
				ON	sk.sketch_id = pa.sketch_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = sk.art_name_id   
			INNER JOIN	Products.Season s
				ON	s.season_id = pa.season_id   
			INNER JOIN	Products.Brand b
				ON	b.brand_id = pa.brand_id
	WHERE	EXISTS (
	     		SELECT	1
	     		FROM	#t t
	     		WHERE	t.pab_id = pab.pab_id
	     	)
	
	
	SELECT	t.pabc_id,
			t.pab_id,
			t.cloth_id,
			t.cloth_name,
			t.color_id,
			t.color_name,
			t.dt,
			t.bcs_id,
			t.bcs_name,
			t.comment,
			t.prev_count_meters,
			t.ordered_count_meters,
			t.actual_count_meters,
			t.rv_bigint
	FROM	#t t

