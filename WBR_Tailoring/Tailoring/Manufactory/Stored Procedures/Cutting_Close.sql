CREATE PROCEDURE [Manufactory].[Cutting_Close]
	@data_xml XML,
	@employee_id INT
AS
	SET NOCOUNT ON
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	
	DECLARE @data_tab TABLE(cutting_id INT PRIMARY KEY)
	
	INSERT INTO @data_tab
	  (
	    cutting_id
	  )
	SELECT	DISTINCT ml.value('@id', 'int')
	FROM	@data_xml.nodes('root/cut')x(ml)
	
	IF EXISTS (
	   	SELECT	1
	   	FROM	@data_tab dt   
	   			LEFT JOIN	Manufactory.Cutting c
	   				ON	c.cutting_id = dt.cutting_id
	   	WHERE	c.cutting_id IS NULL
	   )
	BEGIN
	    RAISERROR('Переданы не корректные данные, обратитесь к разработчику', 16, 1)
	    RETURN
	END
	
	IF EXISTS (
	   	SELECT	1
	   	FROM	@data_tab dt   
	   			LEFT JOIN	Manufactory.CuttingActual ca
	   				ON	dt.cutting_id = ca.cutting_id
	   	WHERE	ca.cutting_id IS NULL
	   )
	BEGIN
	    RAISERROR('Нельзя закрывать позиции с незаполненым количествоми раскроеных комплектов', 16, 1)
	    RETURN
	END
	
	
	BEGIN TRY
		UPDATE	c
		SET 	c.closing_employee_id = @employee_id,
				c.closing_dt = @dt
		FROM	Manufactory.Cutting c
				INNER JOIN	@data_tab dt
					ON	dt.cutting_id = c.cutting_id
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