CREATE PROCEDURE [Logistics].[PlanShipmentFinishedProductsPackingBox_Del]
	@tab dbo.List READONLY,
	@employee_id INT
AS
	SET NOCOUNT ON
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	
	SELECT	@error_text = CASE 
	      	                   WHEN pb.packing_box_id IS NULL THEN 'Коробки с кодом ' + CAST(dt.id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN pb.packing_box_id IS NOT NULL AND pb.close_dt IS NULL THEN 'Коробки с кодом ' + CAST(dt.id AS VARCHAR(10)) + ' не закрыта.'
	      	                   WHEN pb.packing_box_id IS NOT NULL AND psfppb.psfpd_id IS NULL THEN 'Коробки с кодом ' + CAST(dt.id AS VARCHAR(10)) + 
	      	                        ' не запланирована ни в одну отгрузку'
	      	                   WHEN sfppb.sfpd_id IS NOT NULL AND psfppb.sfp_id = sfppb.sfp_id THEN 'Коробка с кодом ' + CAST(dt.id AS VARCHAR(10)) + 
	      	                        ' уже отсканирована в отгрузку № ' + CAST(sfppb.sfp_id AS VARCHAR(10))
	      	                   ELSE NULL
	      	              END
	FROM	@tab dt   
			LEFT JOIN	Logistics.PackingBox pb
				ON	dt.id = pb.packing_box_id   
			LEFT JOIN	Logistics.PlanShipmentFinishedProductsPackingBox psfppb
				ON	psfppb.packing_box_id = pb.packing_box_id   
			LEFT JOIN	Logistics.ShipmentFinishedProductsPackingBox sfppb
				ON	sfppb.packing_box_id = pb.packing_box_id
	
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('(%s).', 16, 1, @error_text)
	    RETURN
	END
	
	
	BEGIN TRY
		BEGIN TRANSACTION 	
		
		DELETE	dpb
		FROM	Logistics.PlanShipmentFinishedProductsPackingBox dpb   
				INNER JOIN	@tab dt
					ON	dpb.packing_box_id = dt.id
		
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