CREATE PROCEDURE [Manufactory].[ChestnyZnakInCirculation_GetList]
@fabricator_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	TOP(200) czic.czic_id,
			CAST(czic.dt AS DATETIME)       dt,
			CAST(czic.dt_send AS DATETIME) dt_send,
			dbo.bin2uid(czic.number_cz)     number_cz
	FROM	Manufactory.ChestnyZnakInCirculation czic
	WHERE czic.fabricator_id = @fabricator_id
	ORDER BY
		czic.czic_id DESC
	