CREATE PROCEDURE [Warehouse].[MaterialInSketch_GetForDoc]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	mis.mis_id,
			mis.shkrm_id,
			rmt.rmt_name,
			cc.color_name,
			a.art_name,
			(mis.stor_unit_residues_qty - ISNULL(mis.return_stor_unit_residues_qty, 0)) qty,
			o2.symbol                    stor_unit_residues_okei_symbol,
			smai.frame_width,
			sma.amount * (mis.stor_unit_residues_qty - ISNULL(mis.return_stor_unit_residues_qty, 0)) / sma.stor_unit_residues_qty amount,
			an.art_name                  sketch_art_name,
			s.sa,
			sj.subject_name,
			b.brand_name,
			oa.x                         sample_info,
			mis.stor_unit_residues_qty,
			mis.return_stor_unit_residues_qty,
			CAST(sma.final_dt AS DATETIME) final_dt,
			s.sketch_id
	FROM	Warehouse.MaterialInSketch mis   
			INNER JOIN	Manufactory.TaskSample ts
				ON	ts.task_sample_id = mis.task_sample_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = mis.sketch_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id   
			INNER JOIN	Products.[Subject] sj
				ON	sj.subject_id = s.subject_id   
			INNER JOIN	Products.Brand b
				ON	b.brand_id = s.brand_id   
			INNER JOIN	Warehouse.SHKRawMaterialInfo smai
				ON	smai.shkrm_id = mis.shkrm_id   
			INNER JOIN	Material.Article a
				ON	a.art_id = smai.art_id   
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = smai.rmt_id   
			INNER JOIN	Qualifiers.OKEI o2
				ON	o2.okei_id = mis.stor_unit_residues_okei_id   
			INNER JOIN	Material.ClothColor cc
				ON	cc.color_id = smai.color_id   
			INNER JOIN	Warehouse.SHKRawMaterialAmount sma
				ON	sma.shkrm_id = smai.shkrm_id   
			OUTER APPLY (
			      	SELECT	st.st_name + ' ' + tecs.ts_name + '; '
			      	FROM	Manufactory.[Sample] s   
			      			INNER JOIN	Manufactory.SampleType st
			      				ON	st.st_id = s.st_id   
			      			INNER JOIN	Products.TechSize tecs
			      				ON	tecs.ts_id = s.ts_id
			      	WHERE	s.task_sample_id = ts.task_sample_id
			      			AND	s.is_deleted = 0
			      	FOR XML	PATH('')
			      ) oa(x)
	WHERE	mis.misd_id IS NULL
			AND	mis.return_dt IS NOT     NULL