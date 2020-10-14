﻿CREATE PROCEDURE [Material].[ClothType_Get]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	ct.ct_id,
			ct.ct_name
	FROM	Material.ClothType ct