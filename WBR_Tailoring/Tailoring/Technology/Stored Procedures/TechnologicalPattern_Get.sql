CREATE PROCEDURE [Technology].[TechnologicalPattern_Get]
	@ct_id INT = NULL,
	@tp_name VARCHAR(50) = NULL,
	@is_deleted BIT = 0,
	@employee_id INT = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	tp.tp_id,
			tp.tp_name,
			tp.ct_id,
			ct.ct_name
	FROM	Technology.TechnologicalPattern tp   
			INNER JOIN	Material.ClothType ct
				ON	ct.ct_id = tp.ct_id
	WHERE	(@ct_id IS NULL OR tp.ct_id = @ct_id)
			AND	(@tp_name IS NULL OR tp.tp_name LIKE @tp_name + '%')
			AND	(@is_deleted IS NULL OR tp.is_deleted = @is_deleted)
			AND (@employee_id IS NULL OR tp.create_employee_id = @employee_id)
	ORDER BY tp.tp_name