CREATE PROCEDURE [Products].[AddedOption_GetBySketch_ForConstructor]
	@sketch_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	DECLARE @subject_id INT
	
	SELECT	@subject_id = s.subject_id
	FROM	Products.Sketch s
	WHERE	s.sketch_id = @sketch_id
	
	SELECT	ao.ao_id,
			ao.ao_name,
			ao2.ao_name parrent_name,
			ao.is_bool,
			s.si_name,
			aot.ao_type_name,
			ao.is_constructor,
			skao.ao_value,
			ao.si_id
	FROM	Products.AddedOption ao   
			LEFT JOIN	Products.SketchAddedOption skao
				ON	skao.ao_id = ao.ao_id
				AND	skao.sketch_id = @sketch_id   
			LEFT JOIN	Products.AddedOption ao2
				ON	ao.ao_id_parent = ao2.ao_id   
			LEFT JOIN	Products.SI s
				ON	s.si_id = ISNULL(ao.si_id, ao2.si_id)   
			LEFT JOIN	Products.AddedOptionType aot
				ON	aot.ao_type_id = ISNULL(ao.ao_type_id, ao.ao_type_id)
	WHERE	ao.isdeleted = 0
			AND	(
			   		(
			   			ao.is_constructor = 1
			   			AND EXISTS(
			   			    	SELECT	1
			   			    	FROM	Products.SubjectAddedOption sao
			   			    	WHERE	(sao.ao_id = ao.ao_id OR sao.ao_id = ao.ao_id_parent)
			   			    			AND	sao.subject_id = @subject_id
			   			    )
			   		)
			   		OR skao.ao_id IS NOT NULL
			   	)
		
		
	