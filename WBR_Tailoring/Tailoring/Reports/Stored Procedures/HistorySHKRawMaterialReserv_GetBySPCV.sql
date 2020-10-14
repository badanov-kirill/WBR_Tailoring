CREATE PROCEDURE [Reports].[HistorySHKRawMaterialReserv_GetBySPCV]
	@spcvc_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	smr.shkrm_id,
			CAST(smr.dt AS DATETIME)     dt,
			smr.quantity,
			o.symbol                     okei_symbol,
			smr.employee_id,
			smr.operation,
			spr.proc_name,
			rmt.rmt_name,
			a.art_name,
			cc.color_name,
			smi.frame_width
	FROM	History.SHKRawMaterialReserv smr   
			LEFT JOIN	Qualifiers.OKEI o
				ON	o.okei_id = smr.okei_id   
			INNER JOIN	History.StoredProcedure spr
				ON	spr.proc_id = smr.proc_id   
			INNER JOIN	Warehouse.SHKRawMaterialInfo smi
				ON	smi.shkrm_id = smr.shkrm_id   
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = smi.rmt_id   
			INNER JOIN	Material.Article a
				ON	a.art_id = smi.art_id   
			INNER JOIN	Material.ClothColor cc
				ON	cc.color_id = smi.color_id
	WHERE	smr.spcvc_id = @spcvc_id
	ORDER BY
		smr.hshrmr_id