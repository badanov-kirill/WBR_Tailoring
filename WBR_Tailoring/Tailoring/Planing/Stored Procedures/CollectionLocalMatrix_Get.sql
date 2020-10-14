CREATE PROCEDURE [Planing].[CollectionLocalMatrix_Get]
	@season_model_year SMALLINT = NULL,
	@season_local_id INT = NULL,
	@brand_id INT = NULL,
	@subject_id INT = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	clm.season_model_year,
			clm.season_local_id,
			clm.brand_id,
			clm.subject_id,
			clm.plan_qty
	FROM	Planing.CollectionLocalMatrix clm
	WHERE	(@season_model_year IS NULL OR clm.season_model_year = @season_model_year)
			AND	(@season_local_id IS NULL OR clm.season_local_id = @season_local_id)
			AND	(@brand_id IS NULL OR clm.brand_id = @brand_id)
			AND	(@subject_id IS NULL OR clm.subject_id = @subject_id)