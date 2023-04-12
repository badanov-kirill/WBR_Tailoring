/*
Обновляется информация Planing.SketchPlan, утверждаются:
-тип изделия
-офис
-период
-предварительный Изготовитель. 

--------------------------------------------------

-09.03.2023 upd Иванилова Е. Добавлено поле fabricator_id

*/
---------------------------------------------------
CREATE PROCEDURE [Planing].[SketchPlan_Approve]
	@sp_id INT,
	@employee_id INT,
	@comment VARCHAR(200) = NULL,
	@office_id INT,
	@fabricator_id INT
AS
	SET NOCOUNT ON 
	
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @status_add TINYINT = 1
	DECLARE @status_addSM TINYINT = 13
	DECLARE @states_approve TINYINT = 2
	DECLARE @states_approveSM TINYINT = 14
	DECLARE @sketch_id INT
	DECLARE @spp_out TABLE (spp_id INT)
	DECLARE @plan_dt DATE
	DECLARE @is_sm BIT = 0
	DECLARE @plan_qty SMALLINT
	DECLARE @cv_qty TINYINT
	DECLARE @ct_id INT
	DECLARE @control_work_time INT
	DECLARE @perimetr DECIMAL(15, 5)
	
	SELECT	@error_text = CASE 
	      	                   WHEN sp.sp_id IS NULL THEN 'Плана с номером ' + CAST(v.sp_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN sp.ps_id = @states_approve THEN 'Этот эскиз уже утвержден'
	      	                   WHEN sp.ps_id NOT IN (@status_add, @status_addSM) THEN 'Эскиз находится в статусе ' + ps.ps_name + ' утверждать нельзя.'
	      	                   WHEN s.pt_id IS NULL THEN 'Не указан тип изделия'
	      	                   WHEN s.ct_id IS NULL THEN 'Не указан ассортимент'
	      	                   --WHEN ISNULL(oa.perimetr, 0) = 0 THEN 'У эскиза не указаны периметры'
	      	                   ELSE NULL
	      	              END,
			@sketch_id     = sp.sketch_id,
			@plan_dt       = sp.plan_sew_dt,
			@is_sm         = CASE 
			              WHEN sp.ps_id = @status_addSM THEN 1
			              ELSE 0
			         END,
			@plan_qty      = sp.plan_qty,
			@cv_qty        = sp.cv_qty,
			@ct_id = s.ct_id,
			@control_work_time = pt.work_time--,
			--@perimetr = oa.perimetr
	FROM	(VALUES(@sp_id))v(sp_id)   
			LEFT JOIN	Planing.SketchPlan sp   
			INNER JOIN	Planing.PlanStatus ps
				ON	ps.ps_id = sp.ps_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = sp.sketch_id
				ON	sp.sp_id = v.sp_id   
			LEFT JOIN Products.ProductType pt
				ON pt.pt_id = s.pt_id
			--OUTER APPLY (
		 --     	SELECT	AVG(spp.perimetr) perimetr 
		 --     	FROM Products.SketchPatternPerimetr spp
		 --     	WHERE	spp.sketch_id = s.sketch_id
		 --     )     oa
	
	
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Settings.OfficeSetting os
	   	WHERE	os.office_id = @office_id
	   )
	BEGIN
	    RAISERROR('Офиса с кодом %d не существует', 16, 1, @office_id)
	    RETURN
	END

	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Settings.Fabricators fs
	   	WHERE	fs.fabricator_id = @fabricator_id 
	   )
	BEGIN
	    RAISERROR('Изготовителя с кодом %d не существует', 16, 1, @fabricator_id)
	    RETURN
	END
	
	BEGIN TRY
		UPDATE	Planing.SketchPlan
		SET 	ps_id = CASE 
		    	             WHEN ps_id = @status_addSM THEN @states_approveSM
		    	             ELSE @states_approve
		    	        END,
				employee_id = @employee_id,
				dt = @dt,
				comment = ISNULL(@comment, comment),
				sew_office_id = CASE 
				                     WHEN ps_id = @status_addSM THEN NULL
				                     ELSE @office_id
				                END,		
				sew_fabricator_id = CASE 
				                     WHEN ps_id = @status_addSM THEN NULL
				                     ELSE @fabricator_id
				                END	
				OUTPUT	INSERTED.sp_id,
						INSERTED.sketch_id,
						INSERTED.ps_id,
						INSERTED.employee_id,
						INSERTED.dt,
						INSERTED.comment
				INTO	History.SketchPlan (
						sp_id,
						sketch_id,
						ps_id,
						employee_id,
						dt,
						comment
					)
		WHERE	sp_id = @sp_id
				AND	ps_id IN (@status_add, @status_addSM)
		
		IF @@ROWCOUNT = 0
		BEGIN
		    RAISERROR('Перечитайте данные, статус уже изменен.', 16, 1)
		    RETURN
		END
		
		IF @is_sm = 1
		BEGIN
		    RETURN
		END
		
		--INSERT INTO Planing.SketchPrePlan
		--	(
		--		sketch_id,
		--		create_employee_id,
		--		create_dt,
		--		employee_id,
		--		dt,
		--		plan_dt,
		--		sew_office_id,
		--		plan_qty,
		--		cv_qty,
		--		sp_id
		--	)OUTPUT	INSERTED.spp_id
		--	 INTO	@spp_out (
		--	 		spp_id
		--	 	)
		--VALUES
		--	(
		--		@sketch_id,
		--		@employee_id,
		--		@dt,
		--		@employee_id,
		--		@dt,
		--		@plan_dt,
		--		@office_id,
		--		@plan_qty,
		--		@cv_qty,
		--		@sp_id
		--	)
		
		--INSERT INTO Planing.SketchPrePlan_TechnologicalSequence
		--	(
		--		spp_id,
		--		operation_range,
		--		ct_id,
		--		ta_id,
		--		element_id,
		--		equipment_id,
		--		dr_id,
		--		dc_id,
		--		operation_value,
		--		discharge_id,
		--		rotaiting,
		--		dc_coefficient,
		--		employee_id,
		--		dt,
		--		comment_id
		--	)
		--SELECT	so.spp_id,
		--		ts.operation_range,
		--		ts.ct_id,
		--		ts.ta_id,
		--		ts.element_id,
		--		ts.equipment_id,
		--		ts.dr_id,
		--		ts.dc_id,
		--		ts.operation_value,
		--		ts.discharge_id,
		--		ts.rotaiting,
		--		ts.dc_coefficient,
		--		ts.employee_id,
		--		ts.dt,
		--		ts.comment_id
		--FROM	Products.TechnologicalSequence ts   
		--		CROSS JOIN	@spp_out so
		--WHERE	ts.sketch_id = @sketch_id
		
		--INSERT INTO Planing.SketchPrePlan_TechnologicalSequence
		--	(
		--		spp_id,
		--		operation_range,
		--		ct_id,
		--		ta_id,
		--		element_id,
		--		equipment_id,
		--		dr_id,
		--		dc_id,
		--		operation_value,
		--		discharge_id,
		--		rotaiting,
		--		dc_coefficient,
		--		employee_id,
		--		dt,
		--		comment_id
		--	)
		--SELECT	so.spp_id,
		--		0 operation_range,
		--		@ct_id ct_id,
		--		108 ta_id, --разрезать
		--		580 element_id, --изделие
		--		26 equipment_id,	--Раскройный стол
		--		2 dr_id, --средняя
		--		1 dc_id, --Без совмещения рисунка
		--		1 operation_value,
		--		1 discharge_id,
		--		@perimetr / 55 ,
		--		1 dc_coefficient,
		--		@employee_id,
		--		@dt,
		--		2472
		--FROM	@spp_out so

		--		INSERT INTO Planing.SketchPrePlan_TechnologicalSequence
		--	(
		--		spp_id,
		--		operation_range,
		--		ct_id,
		--		ta_id,
		--		element_id,
		--		equipment_id,
		--		dr_id,
		--		dc_id,
		--		operation_value,
		--		discharge_id,
		--		rotaiting,
		--		dc_coefficient,
		--		employee_id,
		--		dt,
		--		comment_id
		--	)
		--SELECT	so.spp_id,
		--		oa.operation_range + 1 operation_range ,
		--		@ct_id ct_id,
		--		99 ta_id, --проверить
		--		580 element_id, --изделие
		--		27 equipment_id,	--Стол контроля качества и упаковки
		--		2 dr_id, --средняя
		--		1 dc_id, --Без совмещения рисунка
		--		1 operation_value,
		--		1 discharge_id,
		--		@control_work_time rotaiting,
		--		1 dc_coefficient,
		--		@employee_id,
		--		@dt,
		--		2473
		--FROM	@spp_out so
		--OUTER APPLY (SELECT MAX(st.operation_range) operation_range FROM Planing.SketchPrePlan_TechnologicalSequence st WHERE st.spp_id = so.spp_id) oa
		
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
		--WITH LOG;
	END CATCH 
	