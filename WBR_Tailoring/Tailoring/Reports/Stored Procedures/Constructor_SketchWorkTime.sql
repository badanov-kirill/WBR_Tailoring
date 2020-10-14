CREATE PROCEDURE [Reports].[Constructor_SketchWorkTime]
	@start_dt DATE = NULL,
	@finish_dt DATE = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	s.sketch_id,
			s.sa,
			s.st_id,
			an.art_name,
			sj.subject_name,
			ct.ct_name,
			esc.employee_name     constructor_employee_name,
			esd.employee_name     designer_employee_name,
			qp.qp_name,
			CAST(s.specification_dt AS DATETIME) specification_dt,
			s.season_model_year,
			sl.season_local_name,
			CASE 
			     WHEN ISNULL(s.days_for_purchase, 0) != 0 THEN  CAST(DATEADD(DAY, -(s.days_for_purchase + 60 ), s.plan_site_dt) AS DATETIME)
			     WHEN ISNULL(s.days_for_purchase, 0) = 0 AND s.plan_site_dt < DATEFROMPARTS(2020, 06, 1) THEN CAST(DATEADD(DAY, -75, s.plan_site_dt) AS DATETIME)
			     ELSE CAST(DATEADD(DAY, -180, s.plan_site_dt) AS DATETIME)
			END plan_dt,
			CAST(s.plan_site_dt AS DATETIME) plan_site_dt,
			CAST(oa_sfc.start_constr AS DATETIME) start_constr,
			CAST(oa_sfc.finish_constr AS DATETIME) finish_constr,
			oa_tabw.sum_wt,
			oa_tabw.count_work_day
	FROM	Products.Sketch s   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id   
			INNER JOIN	Products.[Subject] sj
				ON	sj.subject_id = s.subject_id 
			LEFT JOIN Material.ClothType ct
				ON ct.ct_id = s.ct_id  
			LEFT JOIN	Settings.EmployeeSetting esc
				ON	s.constructor_employee_id = esc.employee_id   
			LEFT JOIN	Settings.EmployeeSetting esd
				ON	s.create_employee_id = esd.employee_id   
			LEFT JOIN	Products.QueuePriority qp
				ON	qp.qp_id = s.qp_id   
			LEFT JOIN	Products.SeasonLocal sl
				ON	sl.season_local_id = s.season_local_id   
			OUTER APPLY (
			      	SELECT	MIN(CASE WHEN ss.ss_id = 8 THEN ss.dt ELSE NULL END) start_constr,
			      			MIN(CASE WHEN ss.ss_id IN (10, 22) THEN ss.dt ELSE NULL END) finish_constr
			      	FROM	History.SketchStatus ss
			      	WHERE	ss.sketch_id = s.sketch_id
			      ) oa_sfc
			OUTER APPLY (
	      			SELECT	SUM(et.work_time)     sum_wt,
	      					COUNT(et.work_dt)     count_work_day
	      			FROM	Planing.EmployeeTable et
	      			WHERE	et.work_dt > oa_sfc.start_constr
	      					AND	et.work_dt < oa_sfc.finish_constr
	      					AND	et.work_employee_id = s.constructor_employee_id
				  )                       oa_tabw
	WHERE	(@start_dt IS NULL OR s.construction_close_dt >= @start_dt)
			AND (@finish_dt IS NULL OR	s.construction_close_dt <= @finish_dt)
			AND	s.construction_close_dt IS NOT NULL
	ORDER BY s.construction_close_dt