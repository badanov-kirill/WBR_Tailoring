CREATE PROCEDURE Settings.Declaration_TNVED_Actual_GET
	@declaration_id  INT = NULL
AS

	
	select  d.tnved_id,
	d.tnved_cod,
	d.tnved_desc,
	case when dt.tnved_id is null then 0
		else 1
		end as actual
	FROM	Products.TNVED d
	LEFT JOIN  Settings.Declarations_TNVED dt 
		ON d.tnved_id = dt.tnved_id AND dt.declaration_id = @declaration_id