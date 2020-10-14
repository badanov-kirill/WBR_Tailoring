CREATE PROCEDURE [Material].[CompletingRawMaterial_Get]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	crm.completing_id,
			crm.rmt_id,
			rmt.rmt_name,
			rmt.stor_unit_residues_okei_id okei_id
	FROM	Material.CompletingRawMaterial crm   
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = crm.rmt_id
	ORDER BY
		crm.completing_id,
		rmt.rmt_name		