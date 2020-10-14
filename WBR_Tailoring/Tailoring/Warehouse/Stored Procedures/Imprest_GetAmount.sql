CREATE PROCEDURE [Warehouse].[Imprest_GetAmount]
	@imprest_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	isr.shkrm_id,
			round(sma.amount * isr.stor_unit_residues_qty / sma.stor_unit_residues_qty, 2) amount,
			sma.final_dt
	FROM	Warehouse.ImprestShkRM isr   
			INNER JOIN	Warehouse.SHKRawMaterialAmount sma
				ON	sma.shkrm_id = isr.shkrm_id
	WHERE	isr.imprest_id = @imprest_id
	
	SELECT	isa.sample_id,
			ROUND(oa.sum_amount / oa_cs.cnt_sample, 2) shkrm_amount,
			oa.is_not_final_amount,
			oa.is_not_close,
			oa.cnt_shk
	FROM	Warehouse.ImprestSample isa   
			INNER JOIN	Manufactory.[Sample] s
				ON	s.sample_id = isa.sample_id   
			INNER JOIN	Manufactory.TaskSample ts
				ON	ts.task_sample_id = s.task_sample_id   
			OUTER APPLY (
			      	SELECT	COUNT(s2.sample_id) cnt_sample
			      	FROM	Manufactory.[Sample] s2
			      	WHERE	s2.task_sample_id = ts.task_sample_id
			      			AND	s2.is_deleted = 0
			      ) oa_cs
			OUTER APPLY (
	      			SELECT	SUM(sma.amount * (mis.stor_unit_residues_qty - ISNULL(mis.return_stor_unit_residues_qty, 0)) / sma.stor_unit_residues_qty) sum_amount,
	      					MAX(CASE WHEN sma.final_dt IS NULL THEN 1 ELSE 0 END) is_not_final_amount,
	      					MAX(CASE WHEN mis.return_stor_unit_residues_qty IS NULL THEN 1 ELSE 0 END) is_not_close,
	      					COUNT(mis.shkrm_id) cnt_shk
	      			FROM	Warehouse.MaterialInSketch mis   
	      					INNER JOIN	Warehouse.SHKRawMaterialAmount sma
	      						ON	sma.shkrm_id = mis.shkrm_id
	      			WHERE	mis.task_sample_id = ts.task_sample_id
				  ) oa
	WHERE	isa.imprest_id = @imprest_id