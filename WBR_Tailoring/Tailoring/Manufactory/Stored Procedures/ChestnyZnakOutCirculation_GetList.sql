CREATE PROCEDURE [Manufactory].[ChestnyZnakOutCirculation_GetList]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	TOP(300) czoc.czoc_id,
			CAST(czoc.dt_create AS DATETIME) dt_create,
			CAST(czoc.fiscal_dt AS DATETIME) fiscal_dt,
			czoc.fiscal_num,
			cr.cr_reg_num,
			fa.fa_number,
			CAST(czoc.dt_send AS DATETIME) dt_send,
			dbo.bin2uid(czoc.number_cz)     number_cz
	FROM	Manufactory.ChestnyZnakOutCirculation czoc   
			INNER JOIN	RefBook.CashReg cr
				ON	cr.cr_id = czoc.cr_id   
			INNER JOIN	RefBook.FiscalAccumulator fa
				ON	fa.fa_id = czoc.fa_id
	WHERE	czoc.dt_send IS NULL
			OR	czoc.number_cz IS NOT       NULL
	ORDER BY
		czoc.czoc_id DESC
	