CREATE PROCEDURE [Warehouse].[MaterialInProduction_Get]
	@start_dt dbo.SECONDSTIME,
	@finish_dt dbo.SECONDSTIME,
	@workshop_id INT = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	mip.mip_id,
			mip.workshop_id,
			w.workshop_name,
			CAST(mip.create_dt AS DATETIME) create_dt,
			mip.create_employee_id,
			mip.complite_dt,
			mip.complite_employee_id,
			oa.x sa
	FROM	Warehouse.MaterialInProduction mip   
			LEFT JOIN	Warehouse.Workshop w
				ON	mip.workshop_id = w.workshop_id   
			OUTER APPLY (
			      	SELECT	pa.sa + pan.sa + '(' + an.art_name + ') '
			      	FROM	Warehouse.MaterialInProductionDetailNom mipdn   
			      			INNER JOIN	Products.ProdArticleNomenclature pan
			      				ON	pan.pan_id = mipdn.pan_id   
			      			INNER JOIN	Products.ProdArticle pa
			      				ON	pa.pa_id = pan.pa_id   
			      			INNER JOIN	Products.Sketch s
			      				ON	s.sketch_id = pa.sketch_id   
			      			INNER JOIN	Products.ArtName an
			      				ON	an.art_name_id = s.art_name_id
			      	WHERE	mipdn.mip_id = mip.mip_id
			      	FOR XML	PATH('')
			      ) oa(x)
	WHERE	mip.create_dt >= @start_dt
			AND	mip.create_dt <= @finish_dt
			AND	(@workshop_id IS NULL OR mip.workshop_id = @workshop_id)
