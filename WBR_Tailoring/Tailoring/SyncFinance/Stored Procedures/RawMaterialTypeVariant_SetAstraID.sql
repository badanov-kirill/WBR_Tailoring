CREATE PROCEDURE [SyncFinance].[RawMaterialTypeVariant_SetAstraID]
	@id_tab dbo.List READONLY
AS
	SET NOCOUNT ON
	DECLARE @cnt INT = (SELECT COUNT(1) FROM @id_tab)
	
	IF @cnt = 0
	BEGIN
		RAISERROR('Пустой список идентификаторов',16,1)
		RETURN
	END
		
	BEGIN TRY

		;
		WITH rmt AS
		(
			SELECT TOP(@cnt)	rmt.rmt_id,
					rmt.rmt_astra_id,
					ROW_NUMBER() OVER(ORDER BY rmt.rmt_id) numb
			FROM	Material.RawMaterialTypeVariant rmt
			WHERE	rmt.rmt_astra_id IS NULL AND rmt.art_id IS NOT NULL
		),
		astra_id AS (
			SELECT	i.id        rmt_astra_id,
					ROW_NUMBER() OVER(ORDER BY i.id) numb
			FROM	@id_tab     i
		)
		UPDATE	r
		SET 	rmt_astra_id = a.rmt_astra_id
		FROM	rmt r
				INNER JOIN	astra_id a
					ON	r.numb = a.numb
					
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