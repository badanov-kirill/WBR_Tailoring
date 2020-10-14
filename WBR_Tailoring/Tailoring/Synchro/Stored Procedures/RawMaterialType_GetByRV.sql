CREATE PROCEDURE [Synchro].[RawMaterialType_GetByRV]
	@rv_bigint BIGINT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	DECLARE @rv ROWVERSION = CAST(@rv_bigint AS ROWVERSION)
	
	;
	WITH cte AS (
		SELECT	rmt.rmt_id,
				rmt.rmt_pid,
				rmt.rmt_name,
				rmt.stor_unit_residues_okei_id,
				1                            lvl,
				CAST(rmt.rmt_name AS VARCHAR(MAX)) full_name,
				rmt.rv
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
				rmt.rv
		FROM	Material.RawMaterialType rmt   
				INNER JOIN	cte c
					ON	rmt.rmt_pid = c.rmt_id
	)
	
	SELECT	c.rmt_id,
			c.rmt_pid,
			c.rmt_name,
			c.stor_unit_residues_okei_id     okei_id,
			o.fullname                       okei_name,
			o.symbol,
			c.lvl,
			c.full_name,
			CASE 
			     WHEN ao_child.child_cnt = 0 THEN 0
			     ELSE 1
			END                              this_group,
			CAST(c.rv AS BIGINT) rv_bigint
	FROM	cte c   
			LEFT JOIN	Qualifiers.OKEI o
				ON	o.okei_id = c.stor_unit_residues_okei_id   
			LEFT JOIN	Material.RawMaterialTypeTerminalResidues rmttr
				ON	rmttr.rmt_id = c.rmt_id   
			LEFT JOIN	Material.RawMaterialTypeLimitCancellation rmtlc
				ON	rmtlc.rmt_id = c.rmt_id   
			OUTER APPLY (
			      	SELECT	COUNT(1) child_cnt
			      	FROM	Material.RawMaterialType rmt
			      	WHERE	rmt.rmt_pid = c.rmt_id
			      )                          ao_child
	WHERE	c.rv > @rv
	ORDER BY
		c.rv