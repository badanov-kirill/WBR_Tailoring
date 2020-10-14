CREATE PROCEDURE [SyncFinance].[RawMaterialTypeVariantUpload_Get]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	;
	WITH cte AS
	(
		SELECT	rmt.rmt_id,
				rmt.rmt_pid,
				rmt.rmt_name,
				rmt.stor_unit_residues_okei_id,
				1                            lvl,
				CAST(rmt.rmt_name AS VARCHAR(MAX)) full_name
		FROM	Material.RawMaterialType     rmt
		WHERE	rmt.rmt_pid IS NULL
		UNION
		ALL
		SELECT	rmt.rmt_id,
				rmt.rmt_pid,
				rmt.rmt_name,
				rmt.stor_unit_residues_okei_id,
				c.lvl + 1,
				rmt.rmt_name + ' / ' + c.full_name
		FROM	Material.RawMaterialType rmt   
				INNER JOIN	cte c
					ON	rmt.rmt_pid = c.rmt_id
	)
	SELECT	rmtv.rmt_astra_id            mat_id,
			LEFT(STUFF(rmt.full_name, 1, LEN(rmt.rmt_name), rmt.rmt_name + ' ( ' + ISNULL(a.art_name, '_') + ' ) ' + ISNULL(CAST(rmtv.frame_width AS VARCHAR(10)), '')), 100) mat_name,
			rmt.stor_unit_residues_okei_id okei_id,
			rmtvu.employee_id,
			CAST(rmtvu.rv AS BIGINT)     rv_bigint,
			rmtv.rmtv_id
	FROM	SyncFinance.RawMaterialTypeVariantUpload rmtvu   
			INNER JOIN	Material.RawMaterialTypeVariant rmtv
				ON	rmtv.rmtv_id = rmtvu.rmtv_id   
			LEFT JOIN	Material.Article a
				ON	a.art_id = rmtv.art_id   
			INNER JOIN	cte rmt
				ON	rmt.rmt_id = rmtv.rmt_id
	WHERE	rmtv.rmt_astra_id IS NOT NULL
			AND	rmt.stor_unit_residues_okei_id IS NOT NULL