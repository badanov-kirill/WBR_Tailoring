CREATE PROCEDURE [Suppliers].[RawMaterialStock_Get]
	@rmt_id INT,
	@color_id INT = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	
	SELECT	rms.rms_id,
			rms.supplier_id,
			s.supplier_name,
			rms.rmt_id,
			rmt.rmt_name,
			rms.color_id,
			cc.color_name,
			rms.frame_width,
			rms.okei_id,
			o.symbol okei_symbol,
			rms.qty,
			oa_res.qty_reserv,
			rms.price_cur,
			rms.currency_id,
			c.currency_name_shot,
			rms.price_cur * c.rate_absolute price_ru,
			rms.nds,
			rms.days_delivery_time,
			CAST(rms.end_dt_offer AS DATETIME) end_dt_offer,
			rms.comment
	FROM	Suppliers.RawMaterialStock rms   
			INNER JOIN	Suppliers.Supplier s
				ON	s.supplier_id = rms.supplier_id   
			LEFT JOIN	Material.ClothColor cc
				ON	cc.color_id = rms.color_id   
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = rms.rmt_id   
			INNER JOIN	Qualifiers.OKEI o
				ON	o.okei_id = rms.okei_id   
			INNER JOIN	RefBook.Currency c
				ON	c.currency_id = rms.currency_id
			OUTER APPLY (SELECT SUM(rmsr.qty) qty_reserv
			               FROM Suppliers.RawMaterialStockReserv rmsr WHERE rmsr.rms_id = rms.rms_id) oa_res
	WHERE	rms.rmt_id = @rmt_id
			AND	(@color_id IS NULL OR ISNULL(rms.color_id, 0) = @color_id)
			AND	rms.end_dt_offer > @dt