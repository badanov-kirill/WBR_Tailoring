CREATE PROCEDURE [Planing].[EmployeeTable_Set]
	@data_xml XML,
	@employee_id INT,
	@dt_clear DATE = NULL
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	
	DECLARE @data_tab TABLE(employee_id INT, dt DATE, qty TINYINT)
	
	INSERT INTO @data_tab
		(
			employee_id,
			dt,
			qty
		)
	SELECT	ml.value('@empl[1]', 'int'),
			ml.value('@dt[1]', 'date'),
			ml.value('@qty[1]', 'tinyint')
	FROM	@data_xml.nodes('root/det')x(ml)
	
	SELECT	@error_text = CASE 
	      	                   WHEN dt.qty > 24 OR dt.qty < 0 THEN 'У сотрудника ' + es.employee_name + ' на дату ' + CAST(dt.dt AS VARCHAR(20)) +
	      	                        ' указано неверное количество часов'
	      	                   WHEN dt.employee_id IS NOT NULL AND es.employee_id IS NULL THEN 'Сотрудника с кодом ' + CAST(dt.employee_id AS VARCHAR(10)) +
	      	                        ' не существует.'
	      	                   WHEN dt.employee_id IS NULL THEN 'Не верный ХМЛ'
	      	                   ELSE NULL
	      	              END
	FROM	@data_tab dt   
			LEFT JOIN	Settings.EmployeeSetting es
				ON	es.employee_id = dt.employee_id
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION
		IF @dt_clear IS NOT NULL
		BEGIN
		    DELETE	et
		    FROM	Planing.EmployeeTable et
		    WHERE	et.work_dt >= @dt_clear
		    		AND	EXISTS (
		    		   		SELECT	1
		    		   		FROM	@data_tab dt
		    		   		WHERE	dt.employee_id = et.work_employee_id
		    		   	)
		END 
		
		;		
		MERGE Planing.EmployeeTable t
		USING @data_tab s
				ON s.employee_id = t.work_employee_id
				AND s.dt = t.work_dt
		WHEN MATCHED AND s.qty > 0 THEN 
		     UPDATE	
		     SET 	work_time       = s.qty,
		     		employee_id     = @employee_id,
		     		dt              = @dt
		WHEN MATCHED AND s.qty = 0 THEN
			DELETE
		WHEN NOT MATCHED AND s.qty > 0 THEN 
		     INSERT
		     	(
		     		work_dt,
		     		work_employee_id,
		     		work_time,
		     		employee_id,
		     		dt
		     	)
		     VALUES
		     	(
		     		s.dt,
		     		s.employee_id,
		     		s.qty,
		     		@employee_id,
		     		@dt
		     	);
		
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
		
		
		RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess) WITH LOG;
	END CATCH 
				