CREATE PROCEDURE Material.RawMaterialIncomeOrder_Get
	@doc_id INT,
	@begin_dt DATE,
	@end_dt DATE
AS
	SET NOCOUNT ON 
	SET XACT_ABORT ON
	
	DECLARE @doc_type_id TINYINT = 1 
	;
	WITH cte AS (
	     	SELECT	rmio.rmio_id,
	     			rmio.rmo_id
	     	FROM	Material.RawMaterialIncomeOrder rmio
	     	WHERE	rmio.doc_id = @doc_id
	     			AND	rmio.doc_type_id = @doc_type_id
	     )
	
	SELECT	rmo.rmo_id,
			CAST(rmo.create_dt AS DATETIME) create_dt,
			CAST(rmo.supply_dt AS DATETIME) supply_dt,
			rmo.comment,
			NULL                           rmio_id
	FROM	Suppliers.RawMaterialOrder     rmo
	WHERE	rmo.supplier_id = (
	     		SELECT	rmi.supplier_id
	     		FROM	Material.RawMaterialIncome rmi
	     		WHERE	rmi.doc_id = @doc_id
	     				AND	rmi.doc_type_id = @doc_type_id
	     	)
			AND	rmo.supply_dt BETWEEN @begin_dt AND DATEADD(DAY, 1, @end_dt)
			AND	NOT rmo.rmo_id IN (SELECT	rmo_id
			   	                   FROM	cte) 
	UNION ALL 
	
	SELECT	c.rmo_id,
			CAST(rmo.create_dt AS DATETIME) create_dt,
			CAST(rmo.supply_dt AS DATETIME) supply_dt,
			rmo.comment,
			c.rmio_id
	FROM	cte c   
			INNER JOIN	Suppliers.RawMaterialOrder rmo
				ON	rmo.rmo_id = c.rmo_id
GO	