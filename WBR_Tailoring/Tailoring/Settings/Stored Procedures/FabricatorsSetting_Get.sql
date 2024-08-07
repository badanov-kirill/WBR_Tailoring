﻿CREATE PROCEDURE [Settings].[FabricatorsSetting_Get]
	@fabricator_id INT = NULL,
	@fabricator_activ INT = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT f.fabricator_id,
	       f.fabricator_name,
	       f.activ,
	       f.taxation,
	       f.token,
	       f.EANLogin,
	       f.EANPass,
	       f.INN,
	       f.CZ_ConnectionID,
	       f.CZ_omsId,
	       f.CZ_Token,
	       f.CZ_TokenDT,
	       f.СontactPerson
	FROM   [Settings].Fabricators f
	WHERE  (@fabricator_id IS NULL OR f.fabricator_id = @fabricator_id)
	       AND (@fabricator_activ IS NULL OR f.activ = @fabricator_activ)