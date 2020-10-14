CREATE PROCEDURE [Products].[AddedOption_Get]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	;
	WITH cte_ao AS
	(
		SELECT	ao.ao_id,
				ao.ao_name,
				ao.ao_id_parent,
				ao.ao_name_eng,
				ao.is_bool,
				ao.si_id,
				ao.ao_type_id,
				1                        lvl,
				ao.is_constructor
		FROM	Products.AddedOption     ao
		WHERE	ao.ao_id_parent IS NULL
				AND	ao.isdeleted = 0
		UNION ALL
		SELECT	ao.ao_id,
				ao.ao_name,
				ao.ao_id_parent,
				ao.ao_name_eng,
				ao.is_bool,
				ao.si_id,
				ao.ao_type_id,
				c.lvl + 1,
				ao.is_constructor
		FROM	cte_ao c   
				INNER JOIN	Products.AddedOption ao
					ON	c.ao_id = ao.ao_id_parent
		WHERE	ao.isdeleted = 0
	)
	
	SELECT	DISTINCT ao.ao_id,
			ao.ao_id_parent,
			ao.ao_name,
			ao.ao_name_eng,
			ao.is_bool,
			ao.si_id,
			s.si_name,
			aot.ao_type_name,
			ao.ao_type_id,
			ao.lvl,
			ao.is_constructor
	FROM	cte_ao ao   
			LEFT JOIN	Products.SI s
				ON	s.si_id = ao.si_id   
			INNER JOIN	Products.AddedOptionType aot
				ON	aot.ao_type_id = ao.ao_type_id
	ORDER BY
		ao.lvl,
		ao.ao_name