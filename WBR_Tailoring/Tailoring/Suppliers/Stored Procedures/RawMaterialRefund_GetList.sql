CREATE PROCEDURE [Suppliers].[RawMaterialRefund_GetList]
	@top_n INT = 500,
	@supplier_id INT = NULL,
	@start_create_dt DATETIME2(0) = NULL,
	@finish_create_dt DATETIME2(0) = NULL,
	@sending_dt DATE = NULL,
	@rmrs_id TINYINT = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	TOP(@top_n) 
	      	rmr.rmr_id,
			rmrs.rmrs_name,
			CAST(rmr.create_dt AS DATETIME) create_dt,
			s.supplier_id,
			s.supplier_name,
			CAST(rmr.sending_dt AS DATETIME) sending_dt,
			sc.suppliercontract_code,
			sc.suppliercontract_name,
			CAST(CAST(rmr.rv AS BIGINT) AS VARCHAR(20)) rv_bigint,
			rmr.comment
	FROM	Suppliers.RawMaterialRefund rmr   
			INNER JOIN	Suppliers.RawMaterialRefundStatus rmrs
				ON	rmrs.rmrs_id = rmr.rmrs_id   
			INNER JOIN	Suppliers.Supplier s
				ON	s.supplier_id = rmr.supplier_id   
			INNER JOIN	Suppliers.SupplierContract sc
				ON	sc.suppliercontract_id = rmr.suppliercontract_id
	WHERE	(@supplier_id IS NULL OR @supplier_id = rmr.supplier_id)
			AND	(@start_create_dt IS NULL OR rmr.create_dt >= @start_create_dt)
			AND	(@finish_create_dt IS NULL OR rmr.create_dt <= @finish_create_dt)
			AND	(@sending_dt IS NULL OR rmr.sending_dt = @sending_dt)
			AND	(@rmrs_id IS NULL OR rmr.rmrs_id = @rmrs_id)
	ORDER BY
		rmr.rmr_id DESC
GO