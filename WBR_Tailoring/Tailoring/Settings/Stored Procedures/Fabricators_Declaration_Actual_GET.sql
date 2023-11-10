
CREATE PROCEDURE [Settings].[Fabricators_Declaration_Actual_GET]
	@declaration_id  INT = NULL
AS

	
	select  f.fabricator_id,
	f.fabricator_name,
	case when df.fabricator_id is null then 0
		else 1
		end as actual
	FROM	Settings.Fabricators f
	LEFT JOIN  Settings.Declaration_Fabricators df 
		ON f.fabricator_id = df.fabricator_id AND df.declaration_id = @declaration_id