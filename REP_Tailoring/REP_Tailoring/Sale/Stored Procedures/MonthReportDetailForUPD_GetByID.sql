CREATE PROCEDURE [Sale].[MonthReportDetailForUPD_GetByID]
	@realizationreport_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	
	SELECT	s.subject_name + ', ' + sa.sa_name + ', ' + ts.ts_name item_name,
			mrd.quantity       quantity,
			'796'              okei_id,
			'шт'               okei_name,
			mrd.retail_amount  price,
			mrd.nds            nds,
			'Россия'           country_name,
			643                country_id,
			''                 gtd_cod,
			mrd.shk_id         item_code,
			sa.sa_name         sa,
			ts.ts_name,
			''                 tnved_cod,
			sa.sa_name         sa_imt,
			''                 sa_nm,
			br.brand_name,
			b.barcode          ean,
			s.subject_name     subject_name
	FROM	Sale.MonthReportDetail mrd   
			INNER JOIN	Sale.MonthReport mr
				ON	mr.realizationreport_id = mrd.realizationreport_id   
			INNER JOIN	Products.SupplierArticle sa
				ON	sa.sa_id = mrd.sa_id   
			INNER JOIN	Products.Subjects s
				ON	s.subject_id = mrd.subject_id   
			INNER JOIN	Products.TechSize ts
				ON	ts.ts_id = mrd.ts_id   
			INNER JOIN	Products.Barcodes b
				ON	b.barcode_id = mrd.barcode_id   
			INNER JOIN	Products.Brands br
				ON	br.brand_id = mrd.brand_id
	WHERE	mrd.doc_type_id = 1
			AND	mrd.quantity != 0
			AND	mrd.realizationreport_id = @realizationreport_id
	ORDER BY
		mrd.rrd_id             DESC