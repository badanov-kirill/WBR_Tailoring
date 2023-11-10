
CREATE PROCEDURE [Settings].[Declarations_Get]

	@declaration_id INT = NULL,
	@actual INT = 1,
	@type INT= NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	--case when @actual = 0 then @actual is null end;
SELECT * FROM (	
	SELECT  d.declaration_id,
			d.declaration_number,
			d.start_date,
			d.end_date,
			d.declaration_number + ' с ' + cast(d.start_date as char(10)) + ' по ' + cast(d.end_date as char(10)) as declarationFull,	
			case 
			when  (GETDATE() between d.start_date AND dateadd(DD, -1, d.end_date)) then 1
			else (0)end as actual,
			dt.declaration_type_id,
			dt.declaration_type,
			df.fabricator_id,
			f.fabricator_name,
			df.id as df_id
	FROM	Settings.Declarations d
		inner join Settings.Declaration_types dt 
			on dt.declaration_type_id = d.declaration_type_id
        inner join Settings.Declaration_Fabricators df
			on df.declaration_id = d.declaration_id
		inner join Settings.Fabricators f
			on f.fabricator_id = df.fabricator_id  
	WHERE	(@declaration_id IS NULL
			OR	d.declaration_id = @declaration_id)
			)t
WHERE ((case when @actual = 0 then  null else 1 end) is null or actual = @actual)
	AND (@type is NULL OR declaration_type_id = @type)