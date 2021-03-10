CREATE PROCEDURE [Manufactory].[ChestnyZnakOutCirculationDetail_Get]
	@czoc_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	'01' + oczdi.gtin01 + '21' + oczdi.serial21 cz,
			czocd.price_with_vat
	FROM	Manufactory.ChestnyZnakOutCirculationDetail czocd   
			INNER JOIN	Manufactory.OrderChestnyZnakDetailItem oczdi
				ON	oczdi.oczdi_id = czocd.oczdi_id
	WHERE	czocd.czoc_id = @czoc_id
	
	SELECT	czocdf.gtin01,
			czocdf.serial21,
			czocdf.price_with_vat
	FROM	Manufactory.ChestnyZnakOutCirculationDetailFail czocdf
	WHERE	czocdf.czoc_id = @czoc_id