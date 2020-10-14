CREATE PROCEDURE [Products].[ERP_IMT_ForMapping_Get]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	eifm.imt_id,
			eifm.descr,
			eifm.sa,
			eifm.brand_id,
			eifm.collection_id,
			eifm.season_id,
			eifm.kind_id,
			eifm.subject_id,
			eifm.style_id,
			CAST(eifm.dt AS DATETIME) dt,
			b.brand_name,
			c.collection_name,
			s.season_name,
			k.kind_name,
			sj.subject_name,
			sl.style_name
	FROM	Products.ERP_IMT_ForMapping eifm   
			LEFT JOIN	Products.Brand b
				ON	b.brand_id = eifm.brand_id   
			LEFT JOIN	Products.[Collection] c
				ON	c.collection_id = eifm.collection_id   
			LEFT JOIN	Products.Season s
				ON	s.season_id = eifm.season_id   
			LEFT JOIN	Products.Kind k
				ON	k.kind_id = eifm.kind_id   
			LEFT JOIN	Products.[Subject] sj
				ON	sj.subject_id = eifm.subject_id   
			LEFT JOIN	Products.Style sl
				ON	sl.style_id = eifm.style_id