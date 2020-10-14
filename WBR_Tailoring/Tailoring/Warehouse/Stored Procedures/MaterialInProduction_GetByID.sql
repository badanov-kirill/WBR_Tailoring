CREATE PROCEDURE [Warehouse].[MaterialInProduction_GetByID]
	@mip_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	mip.mip_id,
			mip.workshop_id,
			CAST(mip.create_dt AS DATETIME) create_dt,
			mip.create_employee_id,
			CAST(mip.complite_dt AS DATETIME) complite_dt,
			mip.complite_employee_id,
			CAST(CAST(mip.rv AS BIGINT) AS VARCHAR(19)) rv_bigint
	FROM	Warehouse.MaterialInProduction mip
	WHERE	mip.mip_id = @mip_id
	
	SELECT	mipdn.mipdn_id,
			mipdn.pan_id,
			pa.sa + pan.sa sa,
			an.art_name,
			mipdn.proportion,
			pan.nm_id
	FROM	Warehouse.MaterialInProductionDetailNom mipdn   
			INNER JOIN	Products.ProdArticleNomenclature pan
				ON	pan.pan_id = mipdn.pan_id   
			INNER JOIN	Products.ProdArticle pa
				ON	pa.pa_id = pan.pa_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = pa.sketch_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id
	WHERE	mipdn.mip_id = @mip_id
	
	SELECT	mipds.shkrm_id,
			sma.amount * mipds.stor_unit_residues_qty / sma.stor_unit_residues_qty amount,
			rmt.rmt_name,
			a.art_name,
			mipds.qty,
			o.symbol      okei_symbol,
			mipds.stor_unit_residues_qty,
			o2.symbol     stor_unit_residues_okei_symbol,
			sma.amount * mipds.return_qty / sma.stor_unit_residues_qty return_amount,
			mipds.return_qty,
			CAST(mipds.return_dt AS DATETIME) return_dt
	FROM	Warehouse.MaterialInProductionDetailShk mipds   
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = mipds.rmt_id   
			INNER JOIN	Material.Article a
				ON	a.art_id = mipds.art_id   
			INNER JOIN	Qualifiers.OKEI o
				ON	o.okei_id = mipds.okei_id   
			INNER JOIN	Qualifiers.OKEI o2
				ON	o2.okei_id = mipds.stor_unit_residues_okei_id
			INNER JOIN Warehouse.SHKRawMaterialAmount sma
				ON sma.shkrm_id = mipds.shkrm_id
	WHERE	mipds.mip_id = @mip_id