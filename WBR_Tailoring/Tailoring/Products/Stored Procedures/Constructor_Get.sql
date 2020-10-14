CREATE PROCEDURE [Products].[Constructor_Get]
AS
	SET NOCOUNT ON
	
	SELECT	c.constructor_employee_id
	FROM	Products.Constructor c
GO