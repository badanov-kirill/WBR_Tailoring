CREATE PROCEDURE [Reports].[ProductOperation_Get]
	@start_dt DATE,
	@finish_dt DATE,
	@operation_xml XML = NULL,
	@nm_id INT = NULL
AS
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	DECLARE @operation_tab TABLE(operation_id SMALLINT)
	
	IF @operation_xml IS NULL
	BEGIN
	    SELECT	MAX(po.po_id)            po_id,
	    		po.product_unic_code,
	    		o.operation_name,
	    		pt.pt_name,
	    		pt.pt_rate,
	    		po.office_id,
	    		bo.office_name,
	    		po.employee_id,
	    		CAST(MIN(po.dt) AS DATETIME) dt,
	    		CAST(CAST(MIN(po.dt) AS DATE) AS DATETIME) dt_day,
	    		po.product_unic_code     product_shk,
	    		pan.nm_id,
	    		pa.sa + pan.sa           sa,
	    		sj.subject_name
	    FROM	Manufactory.ProductOperations AS po   
	    		INNER JOIN	Manufactory.ProductUnicCode puc
	    			ON	puc.product_unic_code = po.product_unic_code   
	    		INNER JOIN	Manufactory.Operation AS o
	    			ON	o.operation_id = po.operation_id   
	    		LEFT JOIN	Products.ProductType AS pt
	    			ON	pt.pt_id = puc.pt_id   
	    		INNER JOIN	Settings.OfficeSetting AS bo
	    			ON	bo.office_id = po.office_id   
	    		INNER JOIN	Products.ProdArticleNomenclatureTechSize pants
	    			ON	pants.pants_id = puc.pants_id   
	    		INNER JOIN	Products.ProdArticleNomenclature pan
	    			ON	pan.pan_id = pants.pan_id   
	    		INNER JOIN	Products.ProdArticle pa
	    			ON	pa.pa_id = pan.pa_id
	    		INNER JOIN Products.Sketch s
	    			ON s.sketch_id = pa.sketch_id
	    		INNER JOIN Products.[Subject] sj
	    			ON sj.subject_id = s.subject_id
	    WHERE	po.dt BETWEEN @start_dt AND @finish_dt
	    		AND	(@nm_id IS NULL OR pan.nm_id = @nm_id)
	    		AND po.is_uniq = 1
	    GROUP BY
	    	po.product_unic_code,
	    	o.operation_name,
	    	pt.pt_name,
	    	pt.pt_rate,
	    	po.office_id,
	    	bo.office_name,
	    	po.employee_id,
	    	pan.nm_id,
	    	pa.sa + pan.sa,
	    	sj.subject_name
	END
	ELSE
	BEGIN
	    INSERT INTO @operation_tab
	      (
	        operation_id
	      )
	    SELECT	ml.value('@id', 'smallint') operation_id
	    FROM	@operation_xml.nodes('root/operation')x(ml)	    
	    
	    SELECT	MAX(po.po_id)            po_id,
	    		po.product_unic_code,
	    		o.operation_name,
	    		pt.pt_name,
	    		pt.pt_rate,
	    		po.office_id,
	    		bo.office_name,
	    		po.employee_id,
	    		CAST(MIN(po.dt) AS DATETIME) dt,
	    		CAST(CAST(MIN(po.dt) AS DATE) AS DATETIME) dt_day,
	    		po.product_unic_code     product_shk,
	    		pan.nm_id,
	    		pa.sa + pan.sa           sa,
	    		sj.subject_name
	    FROM	Manufactory.ProductOperations AS po   
	    		INNER JOIN	Manufactory.ProductUnicCode puc
	    			ON	puc.product_unic_code = po.product_unic_code   
	    		INNER JOIN	Manufactory.Operation AS o
	    			ON	o.operation_id = po.operation_id   
	    		LEFT JOIN	Products.ProductType AS pt
	    			ON	pt.pt_id = puc.pt_id   
	    		INNER JOIN	Settings.OfficeSetting AS bo
	    			ON	bo.office_id = po.office_id   
	    		INNER JOIN	Products.ProdArticleNomenclatureTechSize pants
	    			ON	pants.pants_id = puc.pants_id   
	    		INNER JOIN	Products.ProdArticleNomenclature pan
	    			ON	pan.pan_id = pants.pan_id   
	    		INNER JOIN	Products.ProdArticle pa
	    			ON	pa.pa_id = pan.pa_id   
	    		INNER JOIN	@operation_tab ot
	    			ON	ot.operation_id = po.operation_id
	    		INNER JOIN Products.Sketch s
	    			ON s.sketch_id = pa.sketch_id
	    		INNER JOIN Products.[Subject] sj
	    			ON sj.subject_id = s.subject_id
	    WHERE	po.dt BETWEEN @start_dt AND @finish_dt
	    		AND	(@nm_id IS NULL OR pan.nm_id = @nm_id)
	    		AND po.is_uniq = 1
	    GROUP BY
	    	po.product_unic_code,
	    	o.operation_name,
	    	pt.pt_name,
	    	pt.pt_rate,
	    	po.office_id,
	    	bo.office_name,
	    	po.employee_id,
	    	pan.nm_id,
	    	pa.sa + pan.sa,
	    	sj.subject_name
	END;
			