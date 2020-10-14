CREATE PROCEDURE [Reports].[ConstructorTask_ByPeriod]
	@start_dt DATETIME2(0),
	@finish_dt DATETIME2(0),
	@employee_id INT = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	DECLARE @state_complite_constructor TINYINT = 10 --Закончено конструирование
	DECLARE @state_complite_constructor_rework TINYINT = 16 --Доработан конструктором
	DECLARE @state_complite_constructor_only_file TINYINT = 22 --Закончено конструирование только конструкция
	DECLARE @state_complite_constructor_rework_only_file TINYINT = 23 --Доработан конструктором только конструкция 
	
	SELECT	s.constructor_employee_id     employee_id,
			an.art_name,
			s.sa_local,
			b.brand_name,
			CASE 
			     WHEN ss.ss_id = @state_complite_constructor AND s.base_sketch_id IS NULL THEN 1
			     ELSE 0
			END                           new_construction,
			CASE 
			     WHEN ss.ss_id = @state_complite_constructor AND s.base_sketch_id IS NOT NULL THEN 1
			     ELSE 0
			END                           new_construction_from_base,
			CASE 
			     WHEN ss.ss_id = @state_complite_constructor_rework THEN 1
			     ELSE 0
			END                           rework,
			CAST(ss.dt AS DATETIME)       dt,
			CASE 
			     WHEN ss.ss_id = @state_complite_constructor_only_file THEN 1
			     ELSE 0
			END                           only_file,
			CASE 
			     WHEN ss.ss_id = @state_complite_constructor_rework_only_file THEN 1
			     ELSE 0
			END                           rework_only_file,
			CASE 
			     WHEN ss.ss_id IN (@state_complite_constructor, @state_complite_constructor_only_file) THEN s.constructor_coeffecient
			     ELSE 0
			END                           constructor_coeffecient,
			CASE 
			     WHEN ISNULL(s.days_for_purchase, 0) != 0 THEN CAST(DATEADD(DAY, -(s.days_for_purchase + 60), ss.plan_site_dt) AS DATETIME)
			     WHEN ISNULL(s.days_for_purchase, 0) = 0 AND ss.plan_site_dt < DATEFROMPARTS(2020, 06, 1) THEN CAST(DATEADD(DAY, -75, ss.plan_site_dt) AS DATETIME)
			     ELSE CAST(DATEADD(DAY, -180, ss.plan_site_dt) AS DATETIME)
			END                           plan_dt,
			CASE 
			     WHEN DATEDIFF(
			          	DAY,
			          	CASE 
			          	     WHEN ISNULL(s.days_for_purchase, 0) != 0 THEN CAST(DATEADD(DAY, -(s.days_for_purchase + 60), s.plan_site_dt) AS DATETIME)
			          	     WHEN ISNULL(s.days_for_purchase, 0) = 0
			          	AND s.plan_site_dt < DATEFROMPARTS(2020, 06, 1) THEN CAST(DATEADD(DAY, -75, s.plan_site_dt) AS DATETIME)
			          	    ELSE CAST(DATEADD(DAY, -180, s.plan_site_dt) AS DATETIME)
			          	    END,
			          	ss.dt
			          ) 
			          < 0 THEN 0
			     ELSE DATEDIFF(
			          	DAY,
			          	CASE 
			          	     WHEN ISNULL(s.days_for_purchase, 0) != 0 THEN CAST(DATEADD(DAY, -(s.days_for_purchase + 60), s.plan_site_dt) AS DATETIME)
			          	     WHEN ISNULL(s.days_for_purchase, 0) = 0
			          	AND s.plan_site_dt < DATEFROMPARTS(2020, 06, 1) THEN CAST(DATEADD(DAY, -75, s.plan_site_dt) AS DATETIME)
			          	    ELSE CAST(DATEADD(DAY, -180, s.plan_site_dt) AS DATETIME)
			          	    END,
			          	ss.dt
			          )
			END                           day_diff
	FROM	History.SketchStatus ss   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = ss.sketch_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id   
			INNER JOIN	Products.Brand b
				ON	b.brand_id = s.brand_id
	WHERE	ss.dt >= @start_dt
			AND	ss.dt <= @finish_dt
			AND	ss.ss_id     
			   	IN (@state_complite_constructor, @state_complite_constructor_rework, @state_complite_constructor_only_file, @state_complite_constructor_rework_only_file)
			AND	(s.constructor_employee_id = @employee_id OR @employee_id IS NULL)
	ORDER BY
		s.constructor_employee_id,
		s.sketch_id