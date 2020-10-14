CREATE PROCEDURE [Budget].[ProdArticleBudgetCloth_Get]
	@pab_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	pabc.pabc_id,
			pabc.cloth_id,
			c.cloth_name,
			pabc.color_id,
			cc.color_name,
			pabc.dt,
			pabc.bcs_id,
			bcs.bcs_name,
			pabc.comment,
			pabc.prev_count_meters,
			CAST(pabc.rv AS BIGINT) rv_bigint
	FROM	Budget.ProdArticleBudgetCloth pabc   
			INNER JOIN	Material.Cloth c
				ON	c.cloth_id = pabc.cloth_id   
			INNER JOIN	Material.ClothColor cc
				ON	cc.color_id = pabc.color_id   
			INNER JOIN	Budget.BudgetClothStatus bcs
				ON	bcs.bcs_id = pabc.bcs_id
	WHERE	pabc.pab_id = @pab_id
