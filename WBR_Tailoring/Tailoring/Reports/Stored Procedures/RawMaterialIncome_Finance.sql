CREATE PROCEDURE [Reports].[RawMaterialIncome_Finance]
	@supplier_id INT,
	@start_dt DATETIME2(0),
	@finish_dt DATETIME2(0)
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	DECLARE @doc_type_id TINYINT = 1
	
	SELECT	rmi.doc_id,
			CAST(di.create_dt AS DATETIME) create_dt,
			s.supplier_name,
			STUFF(oa_inv.x, 1, 3, '')     invoices,
			rmis.rmis_name,
			STUFF(oa_i.x, 1, 3, '')       invoice_sum,
			v.shk_cnt,
			v.amount_shk                  amount_shk,	-- распределено_на_шк,
			v.write_in_model              write_in_model,	-- списано_на_модели,
			v.write_in_sketch             write_in_sketch,	--списано_на_проработку,
			v.write_in_employee           write_in_employee,	--списано_в_подотчет,
			v.write_in_cancellation       write_in_cancellation,	-- списано_на_хознужды,
			v.in_warehouse                in_warehouse,	--на_мх
			ISNULL(v.amount_shk, 0) - ISNULL(v.write_in_model, 0) - ISNULL(v.write_in_sketch, 0) - ISNULL(v.write_in_employee, 0) 
			- ISNULL(v.write_in_cancellation, 0) - ISNULL(v.in_warehouse, 0) in_work,	--в_работе 
			STUFF(oa_nm.x, 1, 3, '')      nomenclatures
	FROM	Material.RawMaterialIncome rmi
			INNER JOIN Documents.DocumentID di ON di.doc_id = rmi.doc_id AND di.doc_type_id = rmi.doc_type_id   
			INNER JOIN	Material.RawMaterialIncomeStatus rmis
				ON	rmis.rmis_id = rmi.rmis_id   
			INNER JOIN	Suppliers.Supplier s
				ON	s.supplier_id = rmi.supplier_id   
			INNER JOIN	Suppliers.SupplierContract sc
				ON	sc.suppliercontract_id = rmi.suppliercontract_id   
			LEFT JOIN	(SELECT	smi.doc_id,
			    	    	 		smi.doc_type_id,
			    	    	 		COUNT(rmid.shkrm_id) shk_cnt,
			    	    	 		SUM(rmid.amount) amount_shk,
			    	    	 		SUM(sma.amount * ISNULL(vcov.cis_qty, 0) / sma.stor_unit_residues_qty) write_in_model,
			    	    	 		SUM(sma.amount * ISNULL(vmis.mis_qty, 0) / sma.stor_unit_residues_qty) write_in_sketch,
			    	    	 		SUM(isr.amount) write_in_employee,
			    	    	 		SUM(sma.amount * csr.stor_unit_residues_qty / sma.stor_unit_residues_qty) write_in_cancellation,
			    	    	 		SUM(sma.amount * smai.stor_unit_residues_qty / sma.stor_unit_residues_qty) in_warehouse
			    	    	 FROM	Warehouse.SHKRawMaterialInfo smi   
			    	    	 		INNER JOIN	Warehouse.SHKRawMaterialAmount sma
			    	    	 			ON	sma.shkrm_id = smi.shkrm_id   
			    	    	 		LEFT JOIN	Material.RawMaterialIncomeDetail rmid
			    	    	 			ON	rmid.doc_type_id = smi.doc_type_id
			    	    	 			AND	rmid.doc_id = smi.doc_id
			    	    	 			AND	rmid.shkrm_id = sma.shkrm_id   
			    	    	 		LEFT JOIN	(SELECT	cis.shkrm_id,
			    	    	 		    	    	 		SUM(cis.stor_unit_residues_qty - cis.return_stor_unit_residues_qty) cis_qty
			    	    	 		    	    	 FROM	Planing.CoveringIssueSHKRm cis   
			    	    	 		    	    	 		INNER JOIN	Planing.Covering c
			    	    	 		    	    	 			ON	c.covering_id = cis.covering_id
			    	    	 		    	    	 WHERE	c.cost_dt IS NOT NULL
			    	    	 		    	    	 GROUP BY
			    	    	 		    	    	 	cis.shkrm_id)vcov
			    	    	 			ON	vcov.shkrm_id = smi.shkrm_id   
			    	    	 		LEFT JOIN	(SELECT	mis.shkrm_id,
			    	    	 		    	    	 		SUM(mis.stor_unit_residues_qty - mis.return_stor_unit_residues_qty) mis_qty
			    	    	 		    	    	 FROM	Warehouse.MaterialInSketch mis
			    	    	 		    	    	 WHERE	mis.misd_id IS NOT NULL
			    	    	 		    	    	 GROUP BY
			    	    	 		    	    	 	mis.shkrm_id)vmis
			    	    	 			ON	vmis.shkrm_id = smi.shkrm_id   
			    	    	 		LEFT  JOIN	Warehouse.ImprestShkRM isr   
			    	    	 		INNER JOIN	Warehouse.Imprest i
			    	    	 			ON	i.imprest_id = isr.imprest_id
			    	    	 			AND	i.approve_dt IS NOT NULL
			    	    	 			ON	isr.shkrm_id = smi.shkrm_id   
			    	    	 		LEFT JOIN	Warehouse.CancellationShkRM csr   
			    	    	 		INNER JOIN	Warehouse.Cancellation c
			    	    	 			ON	c.cancellation_id = csr.cancellation_id
			    	    	 			AND	c.close_dt IS NOT NULL
			    	    	 			ON	csr.shkrm_id = smi.shkrm_id   
			    	    	 		LEFT JOIN	Warehouse.SHKRawMaterialActualInfo smai   
			    	    	 		INNER JOIN	Warehouse.SHKRawMaterialState sms
			    	    	 			ON	sms.shkrm_id = smai.shkrm_id
			    	    	 			AND	sms.state_id = 3
			    	    	 			ON	smai.shkrm_id = smi.shkrm_id
			    	    	 GROUP BY
			    	    	 	smi.doc_id,
			    	    	 	smi.doc_type_id)v
				ON	v.doc_id = rmi.doc_id
				AND	v.doc_type_id = rmi.doc_type_id   
			OUTER APPLY (
			      	SELECT	' ; ' + CAST(SUM(rmid.amount_with_nds) AS VARCHAR(20))
			      	FROM	Material.RawMaterialInvoice rmi2   
			      			INNER JOIN	Material.RawMaterialInvoiceDetail rmid
			      				ON	rmid.rmi_id = rmi2.rmi_id
			      	WHERE	rmi2.doc_id = rmi.doc_id
			      			AND	rmi2.doc_type_id = rmi.doc_type_id
			      			AND	rmi2.is_deleted = 0
			      	GROUP BY
			      		rmi2.rmi_id
			      	ORDER BY
			      		rmi2.rmi_id
			      	FOR XML	PATH('')
			      ) oa_i(x)
			OUTER APPLY (
			        SELECT	' ; ' + rminv.invoice_name + ' от ' + CAST(rminv.invoice_dt AS VARCHAR(20)) + ''
			        FROM	Material.RawMaterialInvoice rminv
			        WHERE	rminv.doc_id = rmi.doc_id
			         		AND	rminv.doc_type_id = rmi.doc_type_id
			         		AND	rminv.is_deleted = 0
			        ORDER BY
			         	rminv.rmi_id
			        FOR XML	PATH('')
			        ) oa_inv(x)
			OUTER APPLY (
			      	SELECT	' / ' + CAST(pan.nm_id AS VARCHAR(20))
			      	FROM	Warehouse.SHKRawMaterialInfo smi   
			      			INNER JOIN	Warehouse.SHKRawMaterialAmount sma
			      				ON	sma.shkrm_id = smi.shkrm_id   
			      			INNER JOIN	Planing.CoveringIssueSHKRm cis
			      				ON	smi.shkrm_id = cis.shkrm_id   
			      			INNER JOIN	Planing.Covering c
			      				ON	c.covering_id = cis.covering_id   
			      			INNER JOIN	Planing.CoveringDetail cd
			      				ON	cd.covering_id = c.covering_id   
			      			INNER JOIN	Planing.SketchPlanColorVariant spcv
			      				ON	spcv.spcv_id = cd.spcv_id   
			      			INNER JOIN	Products.ProdArticleNomenclature pan
			      				ON	pan.pan_id = spcv.pan_id
			      	WHERE	c.cost_dt IS NOT NULL
			      			AND	smi.doc_id = rmi.doc_id
			      			AND	smi.doc_type_id = rmi.doc_type_id
			      	GROUP BY
			      		pan.nm_id
			      	FOR XML	PATH('')
			      )oa_nm(x)
	WHERE	(@supplier_id IS NULL OR @supplier_id = rmi.supplier_id)
			AND	rmi.doc_type_id = @doc_type_id
			AND	EXISTS(
			   		SELECT	1
			   		FROM	Material.RawMaterialInvoice rminv2
			   		WHERE	rminv2.invoice_dt >= @start_dt
			   				AND	rminv2.invoice_dt <= @finish_dt
			   				AND	rminv2.doc_id = rmi.doc_id
			   				AND	rminv2.doc_type_id = rmi.doc_type_id
			   	)
	ORDER BY
		rmi.doc_id                        DESC