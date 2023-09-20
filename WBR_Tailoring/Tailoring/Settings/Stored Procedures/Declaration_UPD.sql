CREATE PROCEDURE [Settings].[Declaration_UPD]
	@declaration_id INT,
	@declaration_number  VARCHAR(200) = NULL,
	@start_date DATE= NULL,
	@end_date DATE = NULL
AS

UPDATE Settings.Declarations
SET [declaration_number] = ISNULL(@declaration_number,[declaration_number]),
	[start_date] = ISNULL(@start_date,[start_date]),
	[end_date] = ISNULL(@end_date,[end_date])
WHERE [declaration_id] = @declaration_id;