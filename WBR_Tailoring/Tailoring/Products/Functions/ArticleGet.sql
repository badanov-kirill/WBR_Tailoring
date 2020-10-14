CREATE FUNCTION [Products].[ArticleGet]
(
	@brand_id         INT,
	@st_id            INT,
	@model_number     INT,
	@model_year       SMALLINT,
	@season           CHAR(1)
)
RETURNS VARCHAR(20)
AS
BEGIN
	RETURN 
	CASE 
	     WHEN @brand_id = 1 THEN 'St'
	     WHEN @brand_id = 2 THEN 'C'
	     WHEN @brand_id = 5 THEN 'T'
	     WHEN @brand_id = 3 THEN 'H'
	     WHEN @brand_id = 4 THEN 'ber'
	     WHEN @brand_id = 6 THEN 'Ar'
	     WHEN @brand_id = 7 THEN 'Dr'
	     WHEN @brand_id = 8 THEN 'KB'
	     ELSE ''
	END + CAST(@st_id AS VARCHAR(9)) + '-' + CAST(@model_number AS VARCHAR(9)) + '-' + SUBSTRING(CAST(@model_year AS VARCHAR(4)), 3, 2) + @season
END