CREATE PROCEDURE [Technology].[TechActionElement_Get]
	@ta_id INT = NULL,
	@element_id INT = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	tae.ta_id,
			tae.element_id,
			ta.ta_name,
			e.element_name
	FROM	Technology.TechActionElement tae   
			INNER JOIN	Technology.TechAction ta
				ON	ta.ta_id = tae.ta_id   
			INNER JOIN	Technology.Element e
				ON	e.element_id = tae.element_id
	WHERE	(@ta_id IS NULL OR tae.ta_id = @ta_id)
			AND	(@element_id IS NULL OR tae.element_id = @element_id)
			AND ta.is_deleted = 0
			AND e.is_deleted = 0