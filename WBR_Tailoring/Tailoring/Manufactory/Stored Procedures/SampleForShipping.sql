CREATE PROCEDURE [Manufactory].[SampleForShipping]
@start_dt DATE = NULL,
@finish_dt DATE = NULL
AS
	DECLARE @cv_status_placing TINYINT = 12 --Назначен в цех
	DECLARE @cv_status_rm_issue TINYINT = 14 --На выдаче материалов
	DECLARE @cv_status_pre_placing TINYINT = 17 --Подготовлен к запуску
	
	SELECT	CAST(v.sew_deadline_dt AS DATETIME) sew_deadline_dt,
			os.office_name,
			b.brand_name,
			sj.subject_name,
			an.art_name,
			s.sa,
			st.st_name + ' ' + CAST(ROW_NUMBER() OVER(PARTITION BY s.sketch_id ORDER BY sam.sample_id ASC) AS VARCHAR(10)) sample_name,
			ts.ts_name,
			sp.place_name,
			ossp.office_name     place_office_name,
			ossp.office_id       place_office_id,
			sam.sample_id,
			v.sew_office_id,
			s.sketch_id,
			sam.task_sample_id
	FROM	(SELECT	DISTINCT sp.sketch_id,
	    	 		spcv.sew_deadline_dt,
	    	 		spcv.sew_office_id
	    	 FROM	Planing.SketchPlanColorVariant spcv   
	    	 		INNER JOIN	Planing.SketchPlan sp
	    	 			ON	sp.sp_id = spcv.sp_id
	    	 WHERE	spcv.cvs_id IN (@cv_status_placing, @cv_status_rm_issue, @cv_status_pre_placing)
	    	 		AND	spcv.is_deleted = 0
	    	 		AND (@start_dt IS NULL OR spcv.sew_deadline_dt >= @start_dt)
	    	 		AND (@finish_dt IS NULL OR spcv.sew_deadline_dt <= @finish_dt)
	    	 )v   
			INNER JOIN	Settings.OfficeSetting os
				ON	os.office_id = v.sew_office_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = v.sketch_id   
			LEFT JOIN	Manufactory.[Sample] sam   
			INNER JOIN	Manufactory.SampleType st
				ON	st.st_id = sam.st_id   
			INNER JOIN	Products.TechSize ts
				ON	ts.ts_id = sam.ts_id   
			LEFT JOIN	Warehouse.SampleOnPlace sop   
			INNER JOIN	Warehouse.StoragePlace sp   
			INNER JOIN	Warehouse.ZoneOfResponse zor   
			INNER JOIN	Settings.OfficeSetting ossp
				ON	ossp.office_id = zor.office_id
				ON	zor.zor_id = sp.zor_id
				ON	sp.place_id = sop.place_id
				ON	sop.sample_id = sam.sample_id
				ON	sam.sketch_id = s.sketch_id
				AND	sam.st_id IN (2, 4)
				AND	sam.is_deleted = 0   
			INNER JOIN	Products.Brand b
				ON	b.brand_id = s.brand_id   
			INNER JOIN	Products.[Subject] sj
				ON	sj.subject_id = s.subject_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id
	ORDER BY
		v.sew_deadline_dt,
		v.sew_office_id,
		s.sketch_id,
		sam.sample_id