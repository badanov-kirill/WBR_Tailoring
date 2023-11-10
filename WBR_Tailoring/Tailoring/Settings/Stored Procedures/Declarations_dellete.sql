
CREATE PROCEDURE [Settings].[Declarations_dellete]
	@declaration_id  INT
AS

delete from Settings.Declarations_TNVED where declaration_id = @declaration_id
delete from Settings.Declaration_Fabricators where  declaration_id = @declaration_id
delete from Settings.Declarations where  declaration_id = @declaration_id