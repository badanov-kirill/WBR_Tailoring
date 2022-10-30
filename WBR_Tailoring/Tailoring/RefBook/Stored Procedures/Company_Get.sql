CREATE PROCEDURE [RefBook].[Company_Get]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	c.company_id,
			c.company_name,
			c.company_code
	FROM	RefBook.Company c
