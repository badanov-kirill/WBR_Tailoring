CREATE PROCEDURE [Suppliers].[AlterSupplier_Get]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	asu.alter_supplier_id,
			asu.alter_supplier_name,
			asu.label_info
	FROM	Suppliers.AlterSupplier asu
	WHERE	asu.is_deleted = 0