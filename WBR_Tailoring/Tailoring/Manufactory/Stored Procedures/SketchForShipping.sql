CREATE PROCEDURE [Manufactory].[SketchForShipping]
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
			v.sew_office_id,
			s.sketch_id,
			oa_p.x office_pattern
	FROM	(SELECT	TOP(1) WITH TIES sp.sketch_id,
	    	 		spcv.sew_deadline_dt,
	    	 		spcv.sew_office_id
	    	 FROM	Planing.SketchPlanColorVariant spcv   
	    	 		INNER JOIN	Planing.SketchPlan sp
	    	 			ON	sp.sp_id = spcv.sp_id
	    	 WHERE	spcv.cvs_id IN (@cv_status_placing, @cv_status_rm_issue, @cv_status_pre_placing)
	    	 		AND	spcv.is_deleted = 0
	    	 		AND	(@start_dt IS NULL OR spcv.sew_deadline_dt >= @start_dt)
	    	 		AND	(@finish_dt IS NULL OR spcv.sew_deadline_dt <= @finish_dt)
	    	 ORDER BY
	    	 	ROW_NUMBER() OVER(PARTITION BY sp.sketch_id ORDER BY spcv.sew_deadline_dt ASC))v   
			INNER JOIN	Settings.OfficeSetting os
				ON	os.office_id = v.sew_office_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = v.sketch_id   
			INNER JOIN	Products.Brand b
				ON	b.brand_id = s.brand_id   
			INNER JOIN	Products.[Subject] sj
				ON	sj.subject_id = s.subject_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id   
			OUTER APPLY (
			      	SELECT	os.office_name + '; '
			      	FROM	Products.SketchBranchOfficePattern sbop   
			      			INNER JOIN	Settings.OfficeSetting os
			      				ON	os.office_id = sbop.office_id
			      	WHERE	sbop.sketch_id = s.sketch_id
			      	FOR XML	PATH('')
			      ) oa_p(x)
	ORDER BY
		v.sew_deadline_dt,
		v.sew_office_id,
		s.sketch_id