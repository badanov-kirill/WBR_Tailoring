CREATE VIEW Reports.CuttingSew
AS

SELECT	t.pk_date,
		ISNULL(p.plan_count, 0)       plan_count,
		ISNULL(s.actual_count, 0)     actual_count,
		ISNULL(sp .product_unic_code_qty, 0) product_unic_code_qty,
		CASE 
		     WHEN s.actual_count > 0 OR sp .product_unic_code_qty > 0 THEN 0
		     ELSE ISNULL(p.plan_count, 0)
		END                           delta0,
		CASE 
		     WHEN ISNULL(s.actual_count, 0) < ISNULL(sp .product_unic_code_qty, 0) THEN 0
		     ELSE ISNULL(s.actual_count, 0) - ISNULL(sp .product_unic_code_qty, 0)
		END                        AS delta,
		t.sew_office_id,
		t.nm_id
FROM	(SELECT	t.cost_plan_year,
    	 		t.cost_plan_month,
    	 		CAST(CONVERT(CHAR(8), EOMONTH(CONVERT(DATE, CONVERT(CHAR(8), t.cost_plan_year * 10000 + t.cost_plan_month * 100 + 1), 112)), 112) AS INT) 
    	 		pk_date,
    	 		t.spcv_id,
    	 		t.sew_office_id,
    	 		pan.nm_id
    	 FROM	Planing.SketchPlanColorVariant t(NOLOCK)
    			INNER JOIN Products.ProdArticleNomenclature pan ON pan.pan_id = t.pan_id
    	 WHERE	t.cost_plan_year IS NOT NULL
    	 		AND	t.cost_plan_month IS NOT NULL)t   
		LEFT JOIN	(SELECT	t.spcv_id,
		    	     	 		SUM(ca.actual_count) actual_count
		    	     	 FROM	Planing.SketchPlanColorVariantTS t(NOLOCK)   
		    	     	 		INNER JOIN	Manufactory.Cutting c(NOLOCK)
		    	     	 			ON	t.spcvts_id = c.spcvts_id   
		    	     	 		INNER JOIN	Manufactory.CuttingActual ca(NOLOCK)
		    	     	 			ON	ca.cutting_id = c.cutting_id
		    	     	 GROUP BY
		    	     	 	t.spcv_id)s
			ON	s.spcv_id = t.spcv_id   
		INNER JOIN	(SELECT	t.spcv_id,
		    	     	 		SUM(t.cnt) plan_count
		    	     	 FROM	Planing.SketchPlanColorVariantTS t(NOLOCK)
		    	     	 GROUP BY
		    	     	 	t.spcv_id)p
			ON	p.spcv_id = t.spcv_id   
		LEFT JOIN	(SELECT	t.spcv_id,
		    	    	 		COUNT(p.product_unic_code) AS product_unic_code_qty
		    	    	 FROM	Planing.SketchPlanColorVariantTS t(NOLOCK)   
		    	    	 		INNER JOIN	Manufactory.Cutting c(NOLOCK)
		    	    	 			ON	t.spcvts_id = c.spcvts_id   
		    	    	 		INNER JOIN	Manufactory.ProductUnicCode p(NOLOCK)
		    	    	 			ON	p.cutting_id = c.cutting_id
		    	    	 WHERE	p.operation_id IN (1 --На упаковку
		    	    	      	                  , 3 --На списание
		    	    	      	                  , 6 --На упаковку после спецоборудования
		    	    	      	                  , 8 --Печать ШК
		    	    	      	                  , 10 --Отремонтировано после списания
		    	    	      	                  , 12 --Списан крой
		    	    	      	                  )
		    	    	 GROUP BY
		    	    	 	t.spcv_id)sp
			ON	sp .spcv_id = t.spcv_id
