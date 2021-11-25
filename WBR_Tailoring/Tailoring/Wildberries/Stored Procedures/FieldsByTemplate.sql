CREATE PROCEDURE [Wildberries].[FieldsByTemplate]
	@template_id INT = 34
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	f.fields_id,
			f.fields_name
	FROM	Wildberries.Fields f   
			INNER JOIN	Wildberries.TemplatesFields tf
				ON	tf.fields_id = f.fields_id
	WHERE	tf.template_id = @template_id
	ORDER BY
		f.fields_id
