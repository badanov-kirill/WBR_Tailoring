CREATE PROCEDURE [Settings].[OKEI_Get]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	o.okei_id,
			o.fullname,
			o.symbol,
			o.symbol_international,
			o.code,
			o.code_international
	FROM	Qualifiers.OKEI o   
			INNER JOIN	Settings.OKEI o2
				ON	o2.okei_id = o.okei_id