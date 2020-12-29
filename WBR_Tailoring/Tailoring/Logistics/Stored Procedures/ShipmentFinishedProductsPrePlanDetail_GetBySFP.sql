CREATE PROCEDURE [Logistics].[ShipmentFinishedProductsPrePlanDetail_GetBySFP]
@sfp_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	an.art_name,
			b.brand_name,
			sj.subject_name,
			pa.sa + pan.sa       sa,
			sfpppd.cnt,
			sfpppd.sfpppd_id,
			pants.pants_id,
			CAST(sfpppd.start_job_dt AS DATETIME) start_job_dt,
			CAST(sfpppd.finish_job_dt AS DATETIME) finish_job_dt,
			CAST(sfpppd.problem_job_dt AS DATETIME) problem_job_dt,
			es.employee_name     job_employee_name
	FROM	Logistics.ShipmentFinishedProductsPrePlanDetail sfpppd   
			INNER JOIN	Products.ProdArticleNomenclatureTechSize pants
				ON	pants.pants_id = sfpppd.pants_id   
			INNER JOIN	Products.ProdArticleNomenclature pan
				ON	pan.pan_id = pants.pan_id   
			INNER JOIN	Products.ProdArticle pa
				ON	pa.pa_id = pan.pa_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = pa.sketch_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id   
			INNER JOIN	Products.[Subject] sj
				ON	sj.subject_id = s.subject_id   
			INNER JOIN	Products.Brand b
				ON	b.brand_id = pa.brand_id   
			LEFT JOIN	Settings.EmployeeSetting es
				ON	sfpppd.job_employee_id = es.employee_id
	WHERE	sfpppd.sfp_id = @sfp_id
			AND	sfpppd.cnt > 0