CREATE PROCEDURE [Products].[AddedOption_GetBySubject]
	@subject_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	DECLARE @carething_tab TABLE(ao_id INT)
	INSERT INTO @carething_tab
	  (
	    ao_id
	  )
	SELECT	ctao.ao_id
	FROM	Products.CareThingAddedOption ctao
	UNION
	SELECT	ao.ao_id_parent
	FROM	Products.CareThingAddedOption ctao   
			INNER JOIN	Products.AddedOption ao
				ON	ao.ao_id = ctao.ao_id
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
				1                   lvl,
				sao.required_mode
		FROM	Products.SubjectAddedOption sao   
				INNER JOIN	Products.AddedOption ao
					ON	ao.ao_id = sao.ao_id   
				LEFT JOIN	@carething_tab ct
					ON	ct.ao_id = ao.ao_id
		WHERE	sao.subject_id = @subject_id
				AND	ct.ao_id IS     NULL
				AND ao.isdeleted = 0
				AND ao.content_id IS NOT NULL
				AND (ao.ao_id_parent IS NULL OR ao.ao_id_parent != 7)
	)
	,
	cte_parent AS (
		SELECT	c.ao_id,
				c.ao_name,
				c.ao_id_parent,
				c.ao_name_eng,
				c.is_bool,
				c.si_id,
				c.ao_type_id,
				c.lvl,
				c.required_mode
		FROM	cte_ao c
		UNION ALL
		SELECT	ao.ao_id,
				ao.ao_name,
				ao.ao_id_parent,
				ao.ao_name_eng,
				ao.is_bool,
				ao.si_id,
				ao.ao_type_id,
				c.lvl - 1,
				NULL
		FROM	cte_parent c   
				INNER JOIN	Products.AddedOption ao
					ON	ao.ao_id = c.ao_id_parent
		WHERE	NOT EXISTS(
		     		SELECT	1
		     		FROM	cte_ao cao
		     		WHERE	cao.ao_id = ao.ao_id
					)
					AND ao.isdeleted = 0
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
			ao.required_mode,
			ao.lvl
	FROM	cte_parent ao			 
			LEFT JOIN	Products.SI s
				ON	s.si_id = ao.si_id  
			LEFT JOIN	Products.AddedOptionType aot
				ON	aot.ao_type_id = ao.ao_type_id
	ORDER BY
		ao.lvl,
		ao.ao_name