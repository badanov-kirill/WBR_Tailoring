CREATE FUNCTION [Products].[LocalSeasonByMonth]
(
	@month TINYINT
)
RETURNS INT
AS
BEGIN
	RETURN 
	CASE 
	     WHEN @month IN (3, 4, 5) THEN 1
	     WHEN @month IN (6, 7, 8) THEN 2
	     WHEN @month IN (9, 10, 11) THEN 3
	     WHEN @month IN (12, 1, 2) THEN 4
	     ELSE NULL
	END
END
