CREATE PROCEDURE [SyncFinance].[RawMaterialTypeUpload_Get]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	;
	WITH cte AS (
		SELECT	rmt.rmt_id,
				rmt.rmt_pid,
				rmt.rmt_name,
				rmt.stor_unit_residues_okei_id,
				1                            lvl,
				CAST(rmt.rmt_name AS VARCHAR(MAX)) full_name,
				rmt.rmt_astra_id
		FROM	Material.RawMaterialType     rmt
		WHERE	rmt.rmt_pid IS NULL
		UNION
		ALL
		SELECT	rmt.rmt_id,
				rmt.rmt_pid,
				rmt.rmt_name,
				rmt.stor_unit_residues_okei_id,
				c.lvl + 1,
				rmt.rmt_name + ' / ' + c.full_name,
				rmt.rmt_astra_id
		FROM	Material.RawMaterialType rmt   
				INNER JOIN	cte c
					ON	rmt.rmt_pid = c.rmt_id
	)
	SELECT	rmt.rmt_astra_id            mat_id,
			LEFT(rmt.full_name, 100)         mat_name,
			rmt.stor_unit_residues_okei_id okei_id,
			rmtu.employee_id,
			CAST(rmtu.rv AS BIGINT)     rv_bigint,
			rmtu.rmt_id
	FROM	SyncFinance.RawMaterialTypeUpload rmtu   
			INNER JOIN	cte rmt
				ON	rmt.rmt_id = rmtu.rmt_id
	WHERE	rmt.rmt_astra_id IS NOT NULL
			AND	rmt.stor_unit_residues_okei_id IS NOT NULL
