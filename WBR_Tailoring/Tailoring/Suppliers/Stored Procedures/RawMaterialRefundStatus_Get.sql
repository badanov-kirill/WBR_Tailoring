CREATE PROCEDURE [Suppliers].[RawMaterialRefundStatus_Get]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	rmrs.rmrs_id,
			rmrs.rmrs_name
	FROM	Suppliers.RawMaterialRefundStatus rmrs
GO	