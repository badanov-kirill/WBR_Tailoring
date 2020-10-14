CREATE PROCEDURE [Material].[RawMaterialInvoiceCorrectionType_Get]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	rmict.rmict_id,
			rmict.rmict_name
	FROM	Material.RawMaterialInvoiceCorrectionType rmict