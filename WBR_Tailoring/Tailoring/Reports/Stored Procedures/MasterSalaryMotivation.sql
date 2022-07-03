CREATE PROCEDURE [Reports].[MasterSalaryMotivation]
@year SMALLINT,
	@month TINYINT,
	@employee_id INT = NULL,
	@only_my_office BIT = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	DECLARE @dt_start DATETIME2(0) = DATEFROMPARTS(@year, @month, 01)
	DECLARE @dt_finish DATETIME2(0) = DATEADD(MONTH, 1, @dt_start)
	DECLARE @office_id INT
	IF @only_my_office = 1
	BEGIN
	    SELECT	@office_id = es.office_id
	    FROM	Settings.EmployeeSetting es
	    WHERE	es.employee_id = @employee_id
	END
	
	
	SELECT	es.employee_name,
			es.employee_id,
			an.art_name,
			pa.sa + pan.sa     sa,
			SUM(CASE WHEN CAST(puc.packing_dt AS DATE) <= spcv.deadline_package_dt OR spcv.deadline_package_dt IS NULL THEN oat.operation_time ELSE 0 END) 
			hour_on_time,
			SUM(CASE WHEN CAST(puc.packing_dt AS DATE) > spcv.deadline_package_dt THEN oat.operation_time ELSE 0 END) hour_expired,
			SUM(CASE WHEN CAST(puc.packing_dt AS DATE) <= spcv.deadline_package_dt OR spcv.deadline_package_dt IS NULL THEN 1 ELSE 0 END) cnt_on_time,
			SUM(CASE WHEN CAST(puc.packing_dt AS DATE) > spcv.deadline_package_dt THEN 1 ELSE 0 END) cnt_expired,
			CASE 
			     WHEN es.office_id = 523 THEN (SUM(CASE WHEN CAST(puc.packing_dt AS DATE) <= spcv.deadline_package_dt OR spcv.deadline_package_dt IS NULL THEN oat.operation_time ELSE 0 END) * 6
			           + SUM(CASE WHEN CAST(puc.packing_dt AS DATE) > spcv.deadline_package_dt THEN oat.operation_time ELSE 0 END) * 6)
			     ELSE (SUM(CASE WHEN CAST(puc.packing_dt AS DATE) <= spcv.deadline_package_dt OR spcv.deadline_package_dt IS NULL THEN oat.operation_time ELSE 0 END) * 5.0 
			     + SUM(CASE WHEN CAST(puc.packing_dt AS DATE) > spcv.deadline_package_dt THEN oat.operation_time ELSE 0 END) * 5.0)
			END                motivation
	FROM	Manufactory.ProductUnicCode puc   
			INNER JOIN	Manufactory.Cutting c
				ON	c.cutting_id = puc.cutting_id   
			INNER JOIN	Planing.SketchPlanColorVariantTS spcvt
				ON	spcvt.spcvts_id = c.spcvts_id   
			INNER JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.spcv_id = spcvt.spcv_id   
			INNER JOIN	Settings.EmployeeSetting es
				ON	spcv.master_employee_id = es.employee_id   
			INNER JOIN	Products.ProdArticleNomenclature pan
				ON	pan.pan_id = spcv.pan_id   
			INNER JOIN	Products.ProdArticle pa
				ON	pa.pa_id = pan.pa_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = pa.sketch_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id   
			OUTER APPLY (
			      	SELECT	SUM(sts.operation_time) / 3600 operation_time
			      	FROM	Manufactory.SPCV_TechnologicalSequence sts
			      	WHERE	sts.spcv_id = spcv.spcv_id
			      )            oat
	WHERE	puc.packing_dt >= @dt_start
			AND	puc.packing_dt < @dt_finish
			AND	puc.operation_id IN (8, 3, 4, 1, 6)
			AND	(@employee_id IS NULL OR spcv.master_employee_id = @employee_id OR es.office_id = @office_id)
	GROUP BY
		es.employee_name,
		es.employee_id,
		an.art_name,
		pa.sa + pan.sa,
		es.office_id
	ORDER BY
		es.employee_name,
		an.art_name,
		pa.sa + pan.sa
