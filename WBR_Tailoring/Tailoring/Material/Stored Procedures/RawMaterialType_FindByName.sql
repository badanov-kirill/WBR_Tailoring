CREATE PROCEDURE [Material].[RawMaterialType_FindByName]
	@rmt_name VARCHAR(50) = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	;
	WITH cte AS (
		SELECT	rmt.rmt_id,
				rmt.rmt_pid,
				rmt.rmt_name,
				rmt.stor_unit_residues_okei_id,
				1                            lvl
		FROM	Material.RawMaterialType     rmt
		WHERE	rmt.rmt_name LIKE '%' + @rmt_name + '%'
		UNION ALL
		SELECT	rmt.rmt_id,
				rmt.rmt_pid,
				rmt.rmt_name,
				rmt.stor_unit_residues_okei_id,
				c.lvl + 1
		FROM	Material.RawMaterialType rmt   
				INNER JOIN	cte c
					ON	c.rmt_pid = rmt.rmt_id
	)
	SELECT DISTINCT c.rmt_id,
			c.rmt_pid,
			c.rmt_name,
			c.stor_unit_residues_okei_id     okei_id,
			o.fullname                       okei_name
	FROM	cte c   
			LEFT JOIN	Qualifiers.OKEI o
				ON	o.okei_id = c.stor_unit_residues_okei_id 	