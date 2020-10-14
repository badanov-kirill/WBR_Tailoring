CREATE PROCEDURE [Warehouse].[Cancellation_GetList]
	@start_dt DATE,
	@finish_dt DATE,
	@office_id INT = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	c.cancellation_id,
			CAST(c.create_dt AS DATETIME) create_dt,
			c.create_employee_id,
			c.office_id,
			os.office_name,
			c.cancellation_year,
			c.cancellation_month,
			c.close_employee_id,
			CAST(c.close_dt AS DATETIME) closing_dt,
			oa.amount
	FROM	Warehouse.Cancellation c   
			INNER JOIN	Settings.OfficeSetting os
				ON	os.office_id = c.office_id   
			OUTER APPLY (
			      	SELECT	SUM(sma.amount * csr.stor_unit_residues_qty / sma.stor_unit_residues_qty ) amount
			      	FROM	Warehouse.CancellationShkRM csr   
			      			INNER JOIN	Warehouse.SHKRawMaterialAmount sma
			      				ON	sma.shkrm_id = csr.shkrm_id
			      	WHERE	csr.cancellation_id = c.cancellation_id
			) oa
	WHERE	(@office_id IS NULL OR c.office_id = @office_id)
			AND	c.cancellation_dt >= @start_dt
			AND	c.cancellation_dt <= @finish_dt
			
	ORDER BY
		c.cancellation_year,
		c.cancellation_month,
		c.office_id