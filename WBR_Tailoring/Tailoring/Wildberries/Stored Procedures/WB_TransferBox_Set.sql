CREATE PROCEDURE [Wildberries].[WB_TransferBox_Set]
	@data_tab dbo.NameTab READONLY,
	@sfp_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @data_tab_upd TABLE (box_name VARCHAR(20), packing_box_id INT)
	
	SELECT	@error_text = CASE 
	      	                   WHEN s.sfp_id IS NULL THEN 'Отгрузки с номером ' + CAST(v.sfp_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN s.complite_dt IS NOT NULL THEN 'Отгрузка № ' + CAST(s.sfp_id AS VARCHAR(10)) + ' уже отправлена'
	      	                   WHEN oap.cnt_pb != oaw.cnt_wbb THEN 'Не соответствует количество ШК в отгрузке (' + CAST(oap.cnt_pb AS VARCHAR(10)) +
	      	                        ') и ШК коробок ВБ (' + CAST(oaw.cnt_wbb AS VARCHAR(10)) + ')'
	      	                   WHEN oaw.cnt_wbb != oaw.cnt_wbb_dst THEN 'Есть повторяющиеся коды'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@sfp_id))v(sfp_id)   
			LEFT JOIN	Logistics.ShipmentFinishedProducts s
				ON	s.sfp_id = v.sfp_id   
			OUTER APPLY (
			      	SELECT	COUNT(1) cnt_pb
			      	FROM	Logistics.PlanShipmentFinishedProductsPackingBox psfppb
			      	WHERE	psfppb.sfp_id = s.sfp_id
			      ) oap
	OUTER APPLY (
	      	SELECT	COUNT(1)      cnt_wbb,
	      			COUNT(DISTINCT dt.obj_name) cnt_wbb_dst
	      	FROM	@data_tab     dt
	      ) oaw
	
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END	
	
	SELECT	@error_text = CASE 
	      	                   WHEN wtb.box_name IS NOT NULL AND wtb.sfp_id != @sfp_id THEN 'Коробка с кодом ' + wtb.box_name +
	      	                        ' уже подгружена к отгрузке номер ' + CAST(wtb.sfp_id AS VARCHAR(10))
	      	                   ELSE NULL
	      	              END
	FROM	@data_tab dt   
			LEFT JOIN	Wildberries.WB_TransferBox wtb
				ON	wtb.box_name = dt.obj_name
	WHERE	wtb.box_name IS NOT NULL
			AND	wtb.sfp_id != @sfp_id
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END	
	
	INSERT INTO @data_tab_upd
		(
			box_name,
			packing_box_id
		)
	SELECT	v1.obj_name,
			v2.packing_box_id
	FROM	(SELECT	dt.obj_name,
	    	 		ROW_NUMBER() OVER(ORDER BY dt.obj_name) num
	    	 FROM	@data_tab dt)v1(obj_name,
			num)   
			LEFT JOIN	(SELECT	psfppb.packing_box_id,
			    	    	 		ROW_NUMBER() OVER(ORDER BY psfppb.packing_box_id) num
			    	    	 FROM	Logistics.PlanShipmentFinishedProductsPackingBox psfppb
			    	    	 WHERE	psfppb.sfp_id = @sfp_id)v2(packing_box_id,
			num)
				ON	v1.num = v2.num
	
	
	BEGIN TRY
		BEGIN TRANSACTION 
		;
		WITH cte_target AS (
			SELECT	wtb.wbtb_id,
					wtb.box_name,
					wtb.sfp_id,
					wtb.packing_box_id,
					wtb.dt,
					wtb.employee_id
			FROM	Wildberries.WB_TransferBox wtb
			WHERE	wtb.sfp_id = @sfp_id
		)
		MERGE cte_target t
		USING @data_tab_upd s
				ON s.box_name = t.box_name
		WHEN MATCHED THEN 
		     UPDATE	
		     SET 	packing_box_id     = s.packing_box_id,
		     		dt                 = @dt,
		     		employee_id        = @employee_id
		WHEN NOT MATCHED BY TARGET THEN 
		     INSERT
		     	(
		     		box_name,
		     		sfp_id,
		     		packing_box_id,
		     		dt,
		     		employee_id
		     	)
		     VALUES
		     	(
		     		s.box_name,
		     		@sfp_id,
		     		s.packing_box_id,
		     		@dt,
		     		@employee_id
		     	)
		WHEN NOT MATCHED BY SOURCE THEN 
		     DELETE	;
		
		
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