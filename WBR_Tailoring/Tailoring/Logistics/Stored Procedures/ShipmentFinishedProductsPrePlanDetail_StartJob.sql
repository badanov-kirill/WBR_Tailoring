CREATE PROCEDURE [Logistics].[ShipmentFinishedProductsPrePlanDetail_StartJob]
	@sfpppd_id INT,
	@employee_id int
AS
	
	SET NOCOUNT ON
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	
	IF ISNULL(@employee_id, 0) = 0
	BEGIN
	    RAISERROR('Не указан код сотрудника', 16, 1)
	    RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN sfpppd.sfpppd_id IS NULL THEN 'Кода строки ' + CAST(v.sfpppd_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN sfpppd.start_job_dt IS NOT NULL AND ISNULL(sfpppd.job_employee_id, 0) != @employee_id THEN 'Это задание уже взял ' + es.employee_name + ' - ' + CAST(sfpppd.start_job_dt AS VARCHAR(10)) 
	      	                   WHEN sfpppd.finish_job_dt IS NOT NULL THEN 'Это задание уже выполнил ' + es.employee_name + ' - ' + CAST(sfpppd.finish_job_dt AS VARCHAR(10))
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@sfpppd_id))v(sfpppd_id)   
			LEFT JOIN Logistics.ShipmentFinishedProductsPrePlanDetail sfpppd ON sfpppd.sfpppd_id = v.sfpppd_id
			LEFT JOIN Settings.EmployeeSetting es ON es.employee_id = sfpppd.employee_id	
	
	SELECT	@error_text = CASE 
	      	                   WHEN sfpppd		
	
	FROM	Logistics.ShipmentFinishedProductsPrePlanDetail sfpppd
	INNER JOIN Products.ProdArticleNomenclatureTechSize pants ON pants.pants_id = sfpppd.pants_id
	INNER JOIN Products.ProdArticleNomenclature pan
	          ON pan.pan_id = pants.pan_id
	          INNER JOIN Products.ProdArticle pa ON pa.pa_id = pan.pa_id
	WHERE sfpppd.employee_id = @employee_id AND sfpppd.start_job_dt IS NOT NULL AND sfpppd.finish_job_dt IS NULL AND sfpppd.problem_job_dt IS NOT NULL
	
			
	BEGIN TRY
		BEGIN TRANSACTION 	
		
		UPDATE	Logistics.ShipmentFinishedProductsPrePlanDetail
		SET start_job_dt = @dt, job_employee_id = @employee_id
		WHERE sfpppd_id = @sfpppd_id
		AND start_job_dt IS NULL AND finish_job_dt IS NULL		
		
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
		
		RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess) 
		WITH LOG;
	END CATCH
GO