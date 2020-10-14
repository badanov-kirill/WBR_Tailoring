CREATE PROCEDURE [Material].[RawMaterialType_Get]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	rmt.rmt_id,
			rmt.rmt_pid,
			rmt.rmt_name,
			rmt.stor_unit_residues_okei_id okei_id,
			o.fullname                       okei_name,
			rmttr.stor_unit_residues_qty     terminal_residues_qty,
			rmtsm.stuff_model_id
	FROM	Material.RawMaterialType rmt   
			LEFT JOIN	Qualifiers.OKEI o
				ON	o.okei_id = rmt.stor_unit_residues_okei_id   
			LEFT JOIN	Material.RawMaterialTypeTerminalResidues rmttr
				ON	rmttr.rmt_id = rmt.rmt_id
			LEFT JOIN	Material.RawMaterialTypeStuffModel rmtsm
				ON rmtsm.rmt_id = rmt.rmt_id