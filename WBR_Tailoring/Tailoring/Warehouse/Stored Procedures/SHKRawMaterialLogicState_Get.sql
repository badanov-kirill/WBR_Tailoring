CREATE PROCEDURE [Warehouse].[SHKRawMaterialLogicState_Get]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	smlsd.state_id,
			smlsd.state_name,
			smlsd.state_descr
	FROM	Warehouse.SHKRawMaterialLogicStateDict smlsd
	ORDER BY
		smlsd.state_id