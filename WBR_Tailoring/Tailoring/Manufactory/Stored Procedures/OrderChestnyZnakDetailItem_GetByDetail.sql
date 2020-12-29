CREATE PROCEDURE [Manufactory].[OrderChestnyZnakDetailItem_GetByDetail]
	@oczd_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	oczdi.oczdi_id,
			oczdi.code,
			oczdi.gtin01,
			oczdi.serial21,
			oczdi.intrnal91,
			oczdi.intrnal92
	FROM	Manufactory.OrderChestnyZnakDetailItem oczdi
	WHERE	oczdi.oczd_id = @oczd_id
