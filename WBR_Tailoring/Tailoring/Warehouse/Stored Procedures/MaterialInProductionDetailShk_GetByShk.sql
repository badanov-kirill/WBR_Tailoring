CREATE PROCEDURE [Warehouse].[MaterialInProductionDetailShk_GetByShk]
	@shkrm_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	mipds.mip_id,
			mipds.mipds_id,
			CAST(mip.create_dt AS DATETIME) mip_create_dt,
			mipds.shkrm_id,
			sma.amount * mipds.stor_unit_residues_qty / sma.stor_unit_residues_qty amount,
			rmt.rmt_name,
			mipds.rmt_id,
			mipds.art_id,
			a.art_name,
			mipds.qty,
			mipds.okei_id,
			o.symbol                   okei_symbol,
			mipds.stor_unit_residues_qty,
			o2.symbol                  stor_unit_residues_okei_symbol,
			sma.amount * mipds.return_qty / sma.stor_unit_residues_qty return_amount,
			mipds.return_qty,
			CAST(mipds.return_dt AS DATETIME) return_dt,
			smai.rmt_id                s_rmt_id,
			smai.art_id                s_art_id,
			smai.qty                   s_qty,
			smai.okei_id               s_okei_id,
			sma.amount * smai.stor_unit_residues_qty / sma.stor_unit_residues_qty s_amount,
			oa.x                       articles
	FROM	Warehouse.MaterialInProductionDetailShk mipds   
			INNER JOIN	Warehouse.MaterialInProduction mip
				ON	mip.mip_id = mipds.mip_id   
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = mipds.rmt_id   
			INNER JOIN	Material.Article a
				ON	a.art_id = mipds.art_id   
			INNER JOIN	Qualifiers.OKEI o
				ON	o.okei_id = mipds.okei_id   
			INNER JOIN	Qualifiers.OKEI o2
				ON	o2.okei_id = mipds.stor_unit_residues_okei_id   
			LEFT JOIN	Warehouse.SHKRawMaterialActualInfo smai
				ON	smai.shkrm_id = mipds.shkrm_id 
			INNER JOIN Warehouse.SHKRawMaterialAmount sma
				ON sma.shkrm_id = mipds.shkrm_id  
			OUTER APPLY (
			      	SELECT	pa.sa + pan.sa + ' '
			      	FROM	Warehouse.MaterialInProductionDetailNom mipdn   
			      			INNER JOIN	Products.ProdArticleNomenclature pan
			      				ON	pan.pan_id = mipdn.pan_id   
			      			INNER JOIN	Products.ProdArticle pa
			      				ON	pa.pa_id = pan.pa_id
			      	WHERE	mipdn.mip_id = mip.mip_id
			      	FOR XML	PATH('')
			      ) oa(x)
	WHERE	mipds.shkrm_id = @shkrm_id
			AND	mip.complite_dt IS NULL
			AND	mipds.return_dt IS     NULL