CREATE PROCEDURE [Manufactory].[ChestnyZnakReturnCirculation_GetList]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	TOP(300) czrc.czrc_id,
			CAST(czrc.dt_create AS DATETIME) dt_create,
			CAST(czrc.fiscal_dt AS DATETIME) fiscal_dt,
			czrc.fiscal_num,
			cr.cr_reg_num,
			fa.fa_number,
			CAST(czrc.dt_send AS DATETIME) dt_send,
			dbo.bin2uid(czrc.number_cz)     number_cz
	FROM	Manufactory.ChestnyZnakReturnCirculation czrc   
			INNER JOIN	RefBook.CashReg cr
				ON	cr.cr_id = czrc.cr_id   
			INNER JOIN	RefBook.FiscalAccumulator fa
				ON	fa.fa_id = czrc.fa_id
	WHERE	czrc.dt_send IS NULL
			OR	czrc.number_cz IS NOT       NULL
	ORDER BY
		czrc.czrc_id DESC
	