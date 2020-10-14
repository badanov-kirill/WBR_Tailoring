CREATE PROCEDURE [Manufactory].[Cutting_CalculationGet_v2]
	@year INT,
	@month INT,
	@employee_id INT = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	
	DECLARE @dt_start dbo.SECONDSTIME = DATEFROMPARTS(@year, @month, 1)
	DECLARE @dt_finish dbo.SECONDSTIME = DATEADD(MONTH, 1, @dt_start) 
	
	SELECT	cae.employee_id,
			es.employee_name,
			b.brigade_name,
			c.office_id,
			bo.office_name,
			pa.sa + pan.sa              sa,
			CAST(ca.dt AS DATETIME)     dt,
			ct.ct_name,
			SUM(CAST(ca.actual_count AS DECIMAL(15, 2)) / oa_cnt.cnt_empl) actual_count,
			SUM(ca.actual_count * c.perimeter * ISNULL(pan.cutting_degree_difficulty, 1) / oa_cnt.cnt_empl) AS sum_perimetr,
			MAX(ISNULL(pan.cutting_degree_difficulty, 1)) cutting_degree_difficulty,
			SUM(ca.actual_count * c.perimeter * ISNULL(pan.cutting_degree_difficulty, 1) * c.cutting_tariff / oa_cnt.cnt_empl) cut_amount_sum,
			ISNULL(oa_glue_edge.consumption, 0) * SUM(CAST(ca.actual_count AS DECIMAL(15, 2)) / oa_cnt.cnt_empl) glue_edge_m,
			ISNULL(oa_glue_edge.consumption, 0) * SUM(CAST(ca.actual_count AS DECIMAL(15, 2)) / oa_cnt.cnt_empl) * bo.glue_edge_tariff glue_edge_sum,
			SUM(ca.actual_count * c.perimeter * ISNULL(pan.cutting_degree_difficulty, 1) * c.cutting_tariff / oa_cnt.cnt_empl)
			+ ISNULL(oa_glue_edge.consumption, 0) * SUM(CAST(ca.actual_count AS DECIMAL(15, 2)) / oa_cnt.cnt_empl) * bo.glue_edge_tariff sum_amount
	FROM	Manufactory.Cutting c   
			INNER JOIN	Manufactory.CuttingActual ca
				ON	ca.cutting_id = c.cutting_id   
			INNER JOIN	Manufactory.CuttingActualEmployee cae
				ON	cae.ca_id = ca.ca_id   
			INNER JOIN	Products.ProdArticleNomenclatureTechSize pants
				ON	pants.pants_id = c.pants_id   
			INNER JOIN	Products.ProdArticleNomenclature pan
				ON	pan.pan_id = pants.pan_id   
			INNER JOIN	Products.ProdArticle pa
				ON	pa.pa_id = pan.pa_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = pa.sketch_id   
			LEFT JOIN	Material.ClothType ct
				ON	ct.ct_id = s.ct_id   
			INNER JOIN	Settings.OfficeSetting bo
				ON	bo.office_id = c.office_id  
			LEFT JOIN Settings.EmployeeSetting es
				ON es.employee_id = cae.employee_id 
			LEFT JOIN	(SELECT	TOP(1) WITH TIES bed.employee_id,
			    	    	 		bed.brigade_id
			    	    	 FROM	Settings.BrigadeEmployeeDate bed
			    	    	 WHERE	bed.begin_dt <= CAST(@dt_start AS DATE)
			    	    	 ORDER BY
			    	    	 	ROW_NUMBER() OVER(PARTITION BY bed.employee_id ORDER BY bed.begin_dt DESC))v
				ON	v.employee_id = cae.employee_id   
			LEFT JOIN	Settings.Brigade b
				ON	b.brigade_id = v.brigade_id   
			OUTER 	APPLY (
					SELECT	COUNT(cae2.employee_id) cnt_empl
					FROM	Manufactory.CuttingActualEmployee cae2
					WHERE	cae2.ca_id = ca.ca_id
				)                                   oa_cnt
			OUTER APPLY (
				SELECT SUM(sc.consumption) consumption
				FROM Products.SketchCompleting sc
				WHERE sc.sketch_id = s.sketch_id AND sc.completing_id = 11 AND sc.is_deleted = 0	
			)      oa_glue_edge 
	WHERE	ca.dt >= @dt_start
			AND	ca.dt < @dt_finish
			AND	(@employee_id IS NULL OR cae.employee_id = @employee_id)
	GROUP BY
		cae.employee_id,
		es.employee_name,
		b.brigade_name,
		c.office_id,
		bo.office_name,
		cae.employee_id,
		pa.sa + pan.sa,
		ca.dt,
		ct.ct_name,
		oa_glue_edge.consumption,
		bo.glue_edge_tariff
		