CREATE PROCEDURE [Suppliers].[RawMaterialStock_Add]
	@supplier_id INT,
	@rmt_id INT,
	@color_id INT = NULL,
	@frame_width SMALLINT = NULL,
	@okei_id INT,
	@qty DECIMAL(15, 3),
	@price_cur DECIMAL(15, 2),
	@currency_id INT,
	@nds TINYINT,
	@employee_id INT,
	@days_delivery_time TINYINT,
	@end_dt_offer dbo.SECONDSTIME,
	@comment VARCHAR(300) = NULL
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Suppliers.Supplier s
	   	WHERE	s.supplier_id = @supplier_id
	   )
	BEGIN
	    RAISERROR('Поставщика с кодом %d не существует', 16, 1, @supplier_id)
	    RETURN
	END
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Material.RawMaterialType rmt
	   	WHERE	rmt.rmt_id = @rmt_id
	   )
	BEGIN
	    RAISERROR('Типа материала с кодом %d не существует', 16, 1, @rmt_id)
	    RETURN
	END
	
	IF @color_id IS NOT NULL
	   AND NOT EXISTS(
	       	SELECT	1
	       	FROM	Material.ClothColor cc
	       	WHERE	cc.color_id = @color_id
	       )
	BEGIN
	    RAISERROR('Цвета с кодом %d не существует', 16, 1, @color_id)
	    RETURN
	END
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Qualifiers.OKEI o
	   	WHERE	o.okei_id = @okei_id
	   )
	BEGIN
	    RAISERROR('Еденицы измерения с кодом %d не существует', 16, 1, @color_id)
	    RETURN
	END
	
	IF NOT EXISTS (SELECT 1 FROM RefBook.Currency c WHERE c.currency_id = @currency_id)
	BEGIN
	    RAISERROR('Валюты с кодом %d не существует', 16, 1,@currency_id)
	    RETURN
	END
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	RefBook.NDS n
	   	WHERE	n.nds = @nds
	   )
	BEGIN
	    RAISERROR('НДС %d не существует', 16, 1, @nds)
	    RETURN
	END
	
	IF @end_dt_offer <= @dt
	BEGIN
	    RAISERROR('Дата окончания предложения не актуальна', 16, 1)
	    RETURN
	END
	
	
	
	BEGIN TRY
		INSERT INTO Suppliers.RawMaterialStock
		  (
		    supplier_id,
		    rmt_id,
		    color_id,
		    frame_width,
		    okei_id,
		    qty,
		    price_cur,
		    currency_id,
		    nds,
		    dt,
		    employee_id,
		    days_delivery_time,
		    end_dt_offer,
		    comment
		  )OUTPUT	INSERTED.rms_id,
		   		INSERTED.supplier_id,
		   		INSERTED.rmt_id,
		   		INSERTED.color_id,
		   		INSERTED.frame_width,
		   		INSERTED.okei_id,
		   		INSERTED.qty,
		   		INSERTED.price_cur,
		   		INSERTED.currency_id,
		   		INSERTED.nds,
		   		INSERTED.dt,
		   		INSERTED.employee_id,
		   		INSERTED.days_delivery_time,
		   		INSERTED.end_dt_offer,
		   		INSERTED.comment
		   INTO	History.RawMaterialStock (
		   		rms_id,
		   		supplier_id,
		   		rmt_id,
		   		color_id,
		   		frame_width,
		   		okei_id,
		   		qty,
		   		price_cur,
		   		currency_id,
		   		nds,
		   		dt,
		   		employee_id,
		   		days_delivery_time,
		   		end_dt_offer,
		   		comment
		   	)
		VALUES
		  (
		    @supplier_id,
		    @rmt_id,
		    @color_id,
		    @frame_width,
		    @okei_id,
		    @qty,
		    @price_cur,
		    @currency_id,
		    @nds,
		    @dt,
		    @employee_id,
		    @days_delivery_time,
		    @end_dt_offer,
		    @comment
		  )
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
		    ROLLBACK TRANSACTION
		
		DECLARE @ErrNum INT = ERROR_NUMBER();
		DECLARE @estate INT = ERROR_STATE();
		DECLARE @esev INT = ERROR_SEVERITY();
		DECLARE @Line INT = ERROR_LINE();
		DECLARE @Mess VARCHAR(MAX) = CHAR(10) + ISNULL('Процедура: ' + ERROR_PROCEDURE(), '') 
		        + CHAR(10) + ERROR_MESSAGE();
		
		RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess) 
		WITH LOG;
	END CATCH 