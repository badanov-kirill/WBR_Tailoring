CREATE FUNCTION [Products].[ArticleGet_v2]
(
	@brand_id         INT,
	@st_id            INT,
	@model_number     INT,
	@model_year       SMALLINT,
	@season           CHAR(1),
	@direction_id     INT,
	@artpostfix	      varchar(1) = ''
)
RETURNS VARCHAR(20)
AS
BEGIN
	RETURN 
	CASE 
	     WHEN @brand_id = 1 THEN ''
	     WHEN @direction_id = 1 AND @brand_id = 2 THEN 'кле'
	     WHEN @brand_id = 2 THEN 'к'
	     WHEN @brand_id = 5 THEN 'т'
	     WHEN @brand_id = 3 THEN 'н'
	     WHEN @brand_id = 4 THEN 'ber'
	     WHEN @brand_id = 6 THEN 'ar'
	     WHEN @brand_id = 7 THEN 'dr'
	     WHEN @brand_id = 8 THEN 'KB'
	     ELSE ''
	END 
	+
	CASE 
	     WHEN @st_id > 0 AND @st_id < 10 THEN '0'
	     ELSE ''
	END 
	+ CAST(@st_id AS VARCHAR(9)) + CAST(@model_number AS VARCHAR(9)) + SUBSTRING(CAST(@model_year AS VARCHAR(4)), 3, 2) + @season + @artpostfix
END