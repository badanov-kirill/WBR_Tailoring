CREATE PROCEDURE [Reports].[MaterialInProductionDetailShk_NotReturnByEmployee]
	@employee_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	mipds.shkrm_id,
			mip.mip_id,
			w.workshop_name,
			CAST(mip.create_dt AS DATETIME) create_dt,
			oa.x                           sa,
			CAST(mipds.dt AS DATETIME)     dt,
			rmt.rmt_name,
			a.art_name,
			mipds.qty,
			o.symbol                       okei_symbol,
			mipds.employee_id
	FROM	Warehouse.MaterialInProductionDetailShk mipds   
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = mipds.rmt_id   
			INNER JOIN	Material.Article a
				ON	a.art_id = mipds.art_id   
			INNER JOIN	Qualifiers.OKEI o
				ON	o.okei_id = mipds.okei_id   
			INNER JOIN	Warehouse.MaterialInProduction mip
				ON	mip.mip_id = mipds.mip_id   
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
	WHERE	mipds.recive_employee_id = @employee_id
			AND	mip.complite_dt IS NULL
			AND	mipds.return_dt IS         NULL
	ORDER BY
		mip.mip_id,
		mipds.mipds_id