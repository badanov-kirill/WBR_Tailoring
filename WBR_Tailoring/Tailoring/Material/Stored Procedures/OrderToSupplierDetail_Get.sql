CREATE PROCEDURE [Material].[OrderToSupplierDetail_Get]
	@ots_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	otsmd.otsmd_id     id,
			1                  detail_type,
			'Материал'         detail_type_name,
			otsmd.nomenclature_code,
			otsmd.nomenclature_name,
			otsmd.qty,
			otsmd.price,
			otsmd.nds,
			otsmd.amount,
			sm.mat_name        item_name,
			o.symbol           okei_symbol,
			otsmd.price_with_vat
	FROM	Material.OrderToSupplierMaterialDetail otsmd   
			LEFT JOIN	Material.SpecificationMaterial sm
				ON	sm.mat_id = otsmd.mat_id   
			LEFT JOIN	Qualifiers.OKEI o
				ON	o.okei_id = otsmd.okei_id
	WHERE	otsmd.ots_id = @ots_id
	UNION
	ALL
	SELECT	otsmd.otsrsd_id     id,
			2                   detail_type,
			'Услуга',
			otsmd.nomenclature_code,
			otsmd.nomenclature_name,
			otsmd.qty,
			otsmd.price,
			otsmd.nds,
			otsmd.amount,
			sm.rs_name,
			o.symbol            okei_symbol,
			otsmd.price_with_vat
	FROM	Material.OrderToSupplierRenderServiceDetail otsmd   
			LEFT JOIN	Material.SpecificationtRenderService sm
				ON	sm.rs_id = otsmd.rs_id   
			LEFT JOIN	Qualifiers.OKEI o
				ON	o.okei_id = otsmd.okei_id
	WHERE	otsmd.ots_id = @ots_id
	UNION
	ALL
	SELECT	otsmd.otssd_id     id,
			3                  detail_type,
			'ОС',
			otsmd.nomenclature_code,
			otsmd.nomenclature_name,
			otsmd.qty,
			otsmd.price,
			otsmd.nds,
			otsmd.amount,
			ssm.stuff_model_name,
			o.symbol           okei_symbol,
			otsmd.price_with_vat
	FROM	Material.OrderToSupplierStuffDetail otsmd   
			LEFT JOIN	Material.SpecificationStuffModel ssm
				ON	ssm.stuff_model_id = otsmd.stuff_model_id   
			LEFT JOIN	Qualifiers.OKEI o
				ON	o.okei_id = otsmd.okei_id
	WHERE	otsmd.ots_id = @ots_id