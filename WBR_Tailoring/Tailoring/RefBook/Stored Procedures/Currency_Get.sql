CREATE PROCEDURE [RefBook].[Currency_Get]
	@is_base BIT = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	c.currency_id,
			c.currency_name_shot,
			c.currency_name_full,
			c.rate,
			c.devider,
			c.rate_absolute
	FROM	RefBook.Currency c
	WHERE	@is_base IS NULL
			OR	c.is_base = @is_base 