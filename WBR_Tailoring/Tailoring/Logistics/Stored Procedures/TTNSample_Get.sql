CREATE PROCEDURE [Logistics].[TTNSample_Get]
	@ttn_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	t.ttns_id,
			sj.subject_name,
			an.art_name,
			s.sa,
			ts.ts_name,
			sp.place_name,
			ossp.office_name     place_office_name,
			ossp.office_id       place_office_id,
			sam.sample_id,
			s.sketch_id,
			sam.task_sample_id
	FROM	Logistics.TTNSample t   
			INNER JOIN	Manufactory.[Sample] sam
				ON	sam.sample_id = t.sample_id   
			INNER JOIN	Products.TechSize ts
				ON	ts.ts_id = sam.ts_id   
			INNER JOIN	Products.Sketch s
				ON	sam.sketch_id = s.sketch_id   
			LEFT JOIN	Warehouse.SampleOnPlace sop   
			INNER JOIN	Warehouse.StoragePlace sp   
			INNER JOIN	Warehouse.ZoneOfResponse zor   
			INNER JOIN	Settings.OfficeSetting ossp
				ON	ossp.office_id = zor.office_id
				ON	zor.zor_id = sp.zor_id
				ON	sp.place_id = sop.place_id
				ON	sop.sample_id = sam.sample_id   
			INNER JOIN	Products.Brand b
				ON	b.brand_id = s.brand_id   
			INNER JOIN	Products.[Subject] sj
				ON	sj.subject_id = s.subject_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id
	WHERE	t.ttn_id = @ttn_id
	ORDER BY t.ttns_id