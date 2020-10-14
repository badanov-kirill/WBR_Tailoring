CREATE PROCEDURE [Warehouse].[MaterialInSketch_GetByTask]
	@task_sample_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	mis.shkrm_id,
			CAST(mis.dt AS DATETIME)     dt,
			rmt.rmt_name,
			a.art_name,
			mis.qty,
			mis.return_qty,
			o.symbol                     okei_symbol,
			CAST(mis.return_dt AS DATETIME) return_dt,
			cc.color_name,
			smi.frame_width
	FROM	Warehouse.MaterialInSketch mis   
			INNER JOIN	Warehouse.SHKRawMaterialInfo smi
				ON	smi.shkrm_id = mis.shkrm_id   
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = smi.rmt_id   
			INNER JOIN	Material.Article a
				ON	a.art_id = smi.art_id   
			INNER JOIN	Qualifiers.OKEI o
				ON	o.okei_id = mis.okei_id
			INNER JOIN Material.ClothColor cc
				ON cc.color_id = smi.color_id
	WHERE	mis.task_sample_id = @task_sample_id