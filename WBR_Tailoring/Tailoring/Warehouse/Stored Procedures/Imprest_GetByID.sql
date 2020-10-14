CREATE PROCEDURE [Warehouse].[Imprest_GetByID]
	@imprest_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	i.imprest_id,
			CAST(i.create_dt AS DATETIME) create_dt,
			i.create_employee_id,
			i.imprest_office_id,
			i.imprest_employee_id,
			i.comment,
			i.is_deleted,
			i.edit_employee_id,
			i.approve_employee_id,
			CAST(i.approve_dt AS DATETIME) approve_dt,
			CAST(i.rv AS BIGINT)     rv_bigint,
			i.cash_sum
	FROM	Warehouse.Imprest        i
	WHERE	i.imprest_id = @imprest_id
	
	SELECT	csr.shkrm_id,
			a.art_name,
			rmt.rmt_name,
			cc.color_name,
			s.supplier_name,
			o.symbol                     okei_symbol,
			csr.qty,
			o2.symbol                    stor_unit_residues_okei_symbol,
			csr.stor_unit_residues_qty,
			csr.amount,
			csr.frame_width,
			csr.is_defected,
			csr.employee_id,
			CAST(csr.dt AS DATETIME)     dt
	FROM	Warehouse.ImprestShkRM csr   
			INNER JOIN	Material.Article a
				ON	a.art_id = csr.art_id   
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = csr.rmt_id   
			INNER JOIN	Material.ClothColor cc
				ON	cc.color_id = csr.color_id   
			INNER JOIN	Qualifiers.OKEI o
				ON	o.okei_id = csr.okei_id   
			INNER JOIN	Qualifiers.OKEI o2
				ON	o2.okei_id = csr.stor_unit_residues_okei_id   
			INNER JOIN	Suppliers.SupplierContract sc
				ON	sc.suppliercontract_id = csr.suppliercontract_id   
			INNER JOIN	Suppliers.Supplier s
				ON	s.supplier_id = sc.supplier_id   
			INNER JOIN	Warehouse.SHKRawMaterialAmount sma
				ON	sma.shkrm_id = csr.shkrm_id
	WHERE	csr.imprest_id = @imprest_id
	
	SELECT	ism.is_id,
			ism.sample_id,
			ism.shkrm_sample_amount,
			ism.other_amount,
			ism.comment,
			CAST(ism.dt AS DATETIME) dt,
			ism.employee_id,
			b.brand_name,
			sj.subject_name,
			an.art_name,
			s.sa,
			s.sketch_id,
			st.st_name
	FROM	Warehouse.ImprestSample ism   
			INNER JOIN	Manufactory.[Sample] sam
				ON	sam.sample_id = ism.sample_id   
			INNER JOIN	Manufactory.SampleType st
				ON	st.st_id = sam.st_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = sam.sketch_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id   
			INNER JOIN	Products.[Subject] sj
				ON	sj.subject_id = s.subject_id   
			INNER JOIN	Products.Brand b
				ON	b.brand_id = s.brand_id
	WHERE	ism.imprest_id = @imprest_id
	
	SELECT	iod.iod_id,
			iod.iod_num,
			iod.iod_descr,
			iod.iod_amount,
			CAST(iod.dt AS DATETIME)         dt,
			iod.employee_id
	FROM	Warehouse.ImprestOtherDetail     iod
	WHERE	iod.imprest_id = @imprest_id