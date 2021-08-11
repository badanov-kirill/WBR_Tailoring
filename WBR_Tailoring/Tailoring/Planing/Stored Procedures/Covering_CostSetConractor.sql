CREATE PROCEDURE [Planing].[Covering_CostSetConractor]
	@covering_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON 
	SET XACT_ABORT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	
	DECLARE @sketch_tab TABLE (sketch_id INT, cutting_cnt SMALLINT, amount_rm DECIMAL(9, 2), amount_cutting     DECIMAL(9, 2))
	DECLARE @proc_id INT	
	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID
	
	DECLARE @office_id INT

	

	
	SELECT	@error_text = CASE 
	      	                   WHEN c.covering_id IS NULL THEN 'Выдачи с кодом ' + CAST(v.covering_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN c.close_dt IS NULL THEN 'Выдачи с кодом ' + CAST(v.covering_id AS VARCHAR(10)) +
	      	                        ' не закрыта. Записывать себистоимость нельзя'
	      	                   WHEN oaa.cnt_no_return != 0 THEN 'В выдаче есть шк, которые не вернули на склад. Записывать себистоимость нельзя'
	      	                   WHEN oaa.no_close_price != 0 THEN 'В выдаче есть шк, с незакрытым поступлением. Записывать себистоимость нельзя'
	      	                   WHEN oaa.zero_price != 0 THEN 'В выдаче есть шк, с нулевой стоимостью. Записывать себистоимость нельзя'
	      	                   WHEN oaac.actual_count = 0 THEN 'По этой выдаче не внесено количество кроя. Отправлять на себистоимость нельзя'
	      	                   ELSE NULL
	      	              END,
	      	 @office_id = c.office_id
	FROM	(VALUES(@covering_id))v(covering_id)   
			LEFT JOIN	Planing.Covering c
				ON	c.covering_id = v.covering_id   
			OUTER APPLY (
			      	SELECT	CAST(ROUND(SUM(sma.amount * (cis.stor_unit_residues_qty - ISNULL(cis.return_stor_unit_residues_qty, 0)) / sma.stor_unit_residues_qty) ,2,1) AS DECIMAL(9,2))
			      	      	covering_issue_amount,
			      			SUM(CASE WHEN cis.return_dt IS NULL THEN 1 ELSE 0 END) cnt_no_return,
			      			SUM(CASE WHEN sma.final_dt IS NULL THEN 1 ELSE 0 END) no_close_price,
			      			SUM(CASE WHEN sma.amount = 0 THEN 1 ELSE 0 END) zero_price
			      	FROM	Planing.CoveringIssueSHKRm cis   
			      			INNER JOIN	Warehouse.SHKRawMaterialAmount sma
			      				ON	sma.shkrm_id = cis.shkrm_id
			      	WHERE	cis.covering_id = @covering_id
			      			AND ISNULL(cis.return_qty, 0) != cis.qty
			      )oaa
			OUTER APPLY (
	      			SELECT	SUM(ca.actual_count) actual_count
	      			FROM	Manufactory.Cutting cut   
	      					INNER JOIN	Planing.SketchPlanColorVariantTS spcvt
	      						ON	spcvt.spcvts_id = cut.spcvts_id   
	      					INNER JOIN	Planing.SketchPlanColorVariant spcv
	      						ON	spcv.spcv_id = spcvt.spcv_id   
	      					INNER JOIN	Planing.CoveringDetail cd
	      						ON	cd.spcv_id = spcv.spcv_id   
	      					INNER JOIN	Manufactory.CuttingActual ca
	      						ON	ca.cutting_id = cut.cutting_id
	      			WHERE	cd.covering_id = c.covering_id
				  ) oaac
			
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY 
		
		UPDATE	Planing.Covering
		SET 	cost_dt              = @dt,
				cost_employee_id     = @employee_id
		WHERE	covering_id          = @covering_id
		
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
	
