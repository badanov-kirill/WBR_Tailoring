CREATE PROCEDURE [Material].[RawMaterialIncomeExpense_Get]
	@rmie_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	rmie.doc_id,
			rmie.doc_type_id,
			rmie.amount,
			rmie.employee_id,
			CAST(rmie.dt AS DATETIME) dt,
			rmie.descript,
			CAST(rmie.create_dt AS DATETIME) create_dt,
			rmie.create_employee_id
	FROM	Material.RawMaterialIncomeExpense rmie
	WHERE	rmie.rmie_id = @rmie_id
			AND	rmie.is_deleted = 0
GO	