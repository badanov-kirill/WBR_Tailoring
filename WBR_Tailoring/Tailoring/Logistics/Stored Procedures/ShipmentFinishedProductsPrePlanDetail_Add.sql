CREATE PROCEDURE [Logistics].[ShipmentFinishedProductsPrePlanDetail_Add]
@tab dbo.AmountList READONLY,
	@sfp_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	
	SELECT	@error_text = CASE 
	      	                   WHEN pants.pants_id IS NULL THEN 'Цветоразмера с кодом ' + CAST(dt.id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN pants.pants_id IS NOT NULL AND ISNULL(dt.amount, 0) <= 0 THEN 'Количество должно быть больше нуля'
	      	                   ELSE NULL
	      	              END
	FROM	@tab dt   
			LEFT JOIN	Products.ProdArticleNomenclatureTechSize pants
				ON	dt.id = pants.pants_id
	WHERE	pants.pants_id IS NULL
	
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('(%s).', 16, 1, @error_text)
	    RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN s.sfp_id IS NULL THEN 'Отгрузки с номером ' + CAST(v.sfp_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN s.complite_dt IS NOT NULL THEN 'Отгрузка № ' + CAST(s.sfp_id AS VARCHAR(10)) + ' уже отправлена'
	      	                   WHEN s.close_planing_dt IS NOT NULL THEN 'Отгрузка № ' + CAST(s.sfp_id AS VARCHAR(10)) + ' уже закрыта для планирования'
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
		
		;WITH cte_target AS
		(
			SELECT	sfpppd.sfpppd_id,
					sfpppd.sfp_id,
					sfpppd.pants_id,
					sfpppd.cnt,
					sfpppd.dt,
					sfpppd.employee_id
			FROM	Logistics.ShipmentFinishedProductsPrePlanDetail sfpppd
			WHERE	sfpppd.sfp_id = @sfp_id
		)
		MERGE cte_target t
		USING (
		      	SELECT	@sfp_id          sfp_id,
		      			dt.id            pants_id,
		      			dt.amount        cnt,
		      			@dt              dt,
		      			@employee_id     employee_id
		      	FROM	@tab             dt
		      )s(sfp_id, pants_id, cnt, dt, employee_id)
				ON t.pants_id = s.pants_id
		WHEN MATCHED THEN 
		     UPDATE	
		     SET 	cnt             = s.cnt,
		     		dt              = s.dt,
		     		employee_id     = s.employee_id
		WHEN NOT MATCHED BY TARGET THEN 
		     INSERT
		     	(
		     		sfp_id,
		     		pants_id,
		     		cnt,
		     		dt,
		     		employee_id
		     	)
		     VALUES
		     	(
		     		s.sfp_id,
		     		s.pants_id,
		     		s.cnt,
		     		s.dt,
		     		s.employee_id
		     	)
		WHEN NOT MATCHED BY SOURCE THEN 
		     UPDATE	
		     SET 	cnt             = 0,
		     		dt              = @dt,
		     		employee_id     = @employee_id	;
		
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