CREATE PROCEDURE [Logistics].[ShipmentFinishedProducts_OrderWBSet]
	@sfp_id INT,
	@order_wb INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @with_log BIT = 1

	SELECT	@error_text = CASE 
	      	                   WHEN s.order_wb IS NOT NULL THEN 'Заказ ВБ ' + CAST(s.order_wb AS VARCHAR(10)) + ' уже привязяан к отгрузке № ' + CAST(s.sfp_id AS VARCHAR(10))
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@order_wb))v(order_wb)   
			LEFT JOIN	Logistics.ShipmentFinishedProducts s
				ON	s.order_wb = v.order_wb   
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN s.sfp_id IS NULL THEN 'Отгрузки с номером ' + CAST(v.sfp_id AS VARCHAR(10)) + ' не существует.' 
	      	                   WHEN s.order_wb IS NOT NULL THEN 'Отгрузка № ' + CAST(s.sfp_id AS VARCHAR(10)) + ' уже привязана к номеру заказа ВБ ' + CAST(s.order_wb AS VARCHAR(10))
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@sfp_id))v(sfp_id)   
			LEFT JOIN	Logistics.ShipmentFinishedProducts s
				ON	s.sfp_id = v.sfp_id   
		
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		UPDATE	Logistics.ShipmentFinishedProducts
		SET 	employee_id = @employee_id,
				dt = @dt,
				order_wb = @order_wb
		WHERE	sfp_id = @sfp_id
				AND	order_wb IS NULL
		
		IF @@ROWCOUNT = 0
		BEGIN
		    SET @with_log = 0
		    RAISERROR('Отгрузка с номером %d уже связана с заказом', 16, 1, @sfp_id);
		    RETURN
		END 		
				
		COMMIT TRANSACTION
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
		
		IF @with_log = 1
		BEGIN
		    RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess) WITH LOG;
		END
		ELSE
		BEGIN
		    RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess)
		END
	END CATCH 