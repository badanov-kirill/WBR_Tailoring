CREATE PROCEDURE [Warehouse].[MaterialInProduction_GetByPAN]
	@pan_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	mip.mip_id,
			CAST(mip.create_dt AS DATETIME)     dt,
			w.workshop_name,
			an.art_name,
			pa.sa + pan.sa               sa,
			pan.nm_id
	FROM	Settings.EmployeeTransferSetting ets   
			INNER JOIN	Settings.TransferSetting ts
				ON	ts.ts_id = ets.ts_id   
			INNER JOIN	Warehouse.ZoneOfResponse zor
				ON	zor.office_id = ts.office_id   
			INNER JOIN	Warehouse.StoragePlace sp
				ON	sp.zor_id = zor.zor_id   
			INNER JOIN	Warehouse.Workshop w
				ON	w.place_id = sp.place_id   
			INNER JOIN	Warehouse.MaterialInProduction mip
				ON	mip.workshop_id = w.workshop_id   
			INNER JOIN	Warehouse.MaterialInProductionDetailNom mipdn
				ON	mipdn.mip_id = mip.mip_id   
			INNER JOIN	Products.ProdArticleNomenclature pan
				ON	pan.pan_id = mipdn.pan_id   
			INNER JOIN	Products.ProdArticle pa
				ON	pa.pa_id = pan.pa_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = pa.sketch_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id
	WHERE	ets.employee_id = @employee_id
			AND	mip.complite_dt IS NULL
			AND	pan.pan_id = @pan_id