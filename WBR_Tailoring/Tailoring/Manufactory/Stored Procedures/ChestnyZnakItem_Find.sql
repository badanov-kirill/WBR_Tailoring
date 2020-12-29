CREATE PROCEDURE [Manufactory].[ChestnyZnakItem_Find]
	@gtin VARCHAR(14) = NULL,
	@serial VARCHAR(20)
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	oczdi.code,
			oczdi.serial21
	FROM	Manufactory.OrderChestnyZnakDetailItem oczdi
	WHERE	(oczdi.gtin01 LIKE '%' + @gtin + '%' OR oczdi.gtin01 LIKE '01' + @gtin + '%' OR @gtin IS NULL)
			AND	(oczdi.serial21 LIKE '%' + @serial + '%' OR oczdi.serial21 LIKE '21' + @serial + '%')