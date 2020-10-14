CREATE PROCEDURE [Reports].[Sample_GetAllInfo]
	@braind_id INT = NULL,
	@art_name VARCHAR(100) = NULL,
	@sibject_id INT = NULL,
	@on_place BIT = NULL,
	@is_deleted BIT = 0
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	b.brand_name,
			sj.subject_name,
			an.art_name,
			sk.sa,
			qp.qp_name,
			pes.employee_name            pattern_employee_name,
			CAST(ts.pattern_begin_work_dt AS DATETIME) pattern_begin_work_dt,
			CAST(ts.pattern_end_of_work_dt AS DATETIME) pattern_end_of_work_dt,
			ces.employee_name            cut_employee_name,
			CAST(ts.cut_begin_work_dt AS DATETIME) cut_begin_work_dt,
			CAST(ts.cut_end_of_work_dt AS DATETIME) cut_end_of_work_dt,
			CAST(ts.create_dt AS DATETIME) dt,
			ISNULL(ts.pattern_comment + ' / ', '') + ISNULL(ts.cut_comment, '') comment,
			CAST(ts.problem_dt AS DATETIME) problem_dt,
			ts.problem_comment,
			s.sample_id,
			s.sketch_id,
			st.st_name,
			tsz.ts_name,
			ct.ct_name,
			s.comment                    smaple_comment,
			s.pattern_perimeter,
			s.cut_perimeter,
			s.is_deleted                 sample_is_deleted,
			ts.is_deleted                task_is_deleted,
			sop.place_id,
			sp.place_name,
			os.office_name               place_office_name,
			CAST(sop.dt AS DATETIME)     place_dt
	FROM	Manufactory.[Sample] s   
			INNER JOIN	Products.Sketch sk
				ON	sk.sketch_id = s.sketch_id   
			INNER JOIN	Products.[Subject] sj
				ON	sj.subject_id = sk.subject_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = sk.art_name_id   
			INNER JOIN	Products.Brand b
				ON	b.brand_id = sk.brand_id   
			INNER JOIN	Manufactory.SampleType st
				ON	st.st_id = s.st_id   
			INNER JOIN	Products.TechSize tsz
				ON	tsz.ts_id = s.ts_id   
			INNER JOIN	Material.ClothType ct
				ON	ct.ct_id = s.ct_id   
			LEFT JOIN	Manufactory.TaskSample ts   
			INNER JOIN	Products.QueuePriority qp
				ON	qp.qp_id = ts.qp_id   
			LEFT JOIN	Settings.EmployeeSetting pes
				ON	ts.pattern_employee_id = pes.employee_id   
			LEFT JOIN	Settings.EmployeeSetting ces
				ON	ts.cut_employee_id = ces.employee_id
				ON	ts.task_sample_id = s.task_sample_id   
			LEFT JOIN	Warehouse.SampleOnPlace sop   
			INNER JOIN	Warehouse.StoragePlace sp   
			INNER JOIN	Warehouse.ZoneOfResponse zor
				ON	zor.zor_id = sp.zor_id   
			INNER JOIN	Settings.OfficeSetting os
				ON	zor.office_id = os.office_id
				ON	sp.place_id = sop.place_id
				ON	sop.sample_id = s.sample_id
	WHERE	s.is_deleted = @is_deleted
			AND	ISNULL(ts.is_deleted, 0) = @is_deleted
			AND	(@braind_id IS NULL OR sk.brand_id = @braind_id)
			AND	(@art_name IS NULL OR an.art_name LIKE @art_name + '%')
			AND	(@sibject_id IS NULL OR sk.subject_id = @sibject_id)
			AND	(@on_place IS NULL OR (@on_place = 1 AND sop.sample_id IS NOT NULL) OR (@on_place = 0 AND sop.sample_id IS NULL))
	
