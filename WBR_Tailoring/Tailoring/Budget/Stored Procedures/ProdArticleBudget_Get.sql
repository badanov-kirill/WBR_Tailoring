CREATE PROCEDURE [Budget].[ProdArticleBudget_Get]
	@year SMALLINT,
	@month TINYINT,
	@bs_id INT = NULL,
	@office_id INT = NULL,
	@brand_id INT = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	pab.pab_id,
			pab.plan_count,
			pab.plan_year,
			pab.plan_month,
			pab.comment,
			sk.sa_local                article,
			an.art_name,
			pa.brand_id,
			b.brand_name,
			pa.season_id,
			s.season_name,
			pab.planing_employee_id,
			CAST(pab.rv AS BIGINT)     rv_bigint,
			s2.subject_name,
			sk.constructor_employee_id,
			pab.bs_id,
			pab.office_id,
			pa.sketch_id
	FROM	Products.ProdArticle pa   
			INNER JOIN	Products.Sketch sk
				ON	sk.sketch_id = pa.sketch_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = sk.art_name_id   
			INNER JOIN	Products.Season s
				ON	s.season_id = pa.season_id   
			INNER JOIN	Products.Brand b
				ON	b.brand_id = pa.brand_id   
			INNER JOIN	Budget.ProdArticleBudget pab
				ON	pab.pa_id = pa.pa_id   
			INNER JOIN	Products.[Subject] s2
				ON	s2.subject_id = sk.subject_id
	WHERE	pab.plan_year = @year
			AND	pab.plan_month = @month
			AND	(@bs_id IS NULL OR pab.bs_id = @bs_id)
			AND	(@office_id IS NULL OR pab.office_id = @office_id)
			AND	(@brand_id IS NULL OR pa.brand_id = @brand_id)
			AND pa.is_deleted = 0