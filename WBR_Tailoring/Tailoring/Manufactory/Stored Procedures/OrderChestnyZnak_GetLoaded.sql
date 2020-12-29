CREATE PROCEDURE [Manufactory].[OrderChestnyZnak_GetLoaded]
	@start_dt DATE = NULL,
	@finish_dt DATE = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	ocz.ocz_id,
			CAST(ocz.create_dt AS DATETIME) create_dt,
			CAST(ocz.dt AS DATETIME)         dt,
			ocz.employee_id,
			ocz.covering_id,
			LOWER(dbo.bin2uid(ocz.ocz_uid)) ocz_uid
	FROM	Manufactory.OrderChestnyZnak     ocz
	WHERE	ocz.is_deleted = 0
			AND	ocz.close_dt IS NOT NULL
			AND	(@start_dt IS NULL OR ocz.create_dt >= @start_dt)
			AND	(@finish_dt IS NULL OR ocz.create_dt < DATEADD(DAY, 1, @finish_dt))

	
