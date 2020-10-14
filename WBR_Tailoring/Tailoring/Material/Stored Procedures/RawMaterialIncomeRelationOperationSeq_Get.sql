CREATE PROCEDURE [Material].[RawMaterialIncomeRelationOperationSeq_Get]
AS
	
	SET NOCOUNT ON
	
	SELECT NEXT VALUE FOR Material.RawMaterialIncomeRelationOperationSeq operation_num