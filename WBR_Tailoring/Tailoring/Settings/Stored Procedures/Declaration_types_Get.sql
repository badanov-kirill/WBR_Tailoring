﻿CREATE PROCEDURE [Settings].[Declaration_types_Get]

AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT * FROM [Settings].[Declaration_types]