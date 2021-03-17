CREATE PROCEDURE [Manufactory].[ChestnyZnakCirculation_Set]
	@detail Manufactory.ChestnyZnakCirculationTab READONLY,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	
	DECLARE @doc_out AS TABLE (czoc_id INT, fiscal_num INT, cr_id INT, fa_id INT, fiscal_dt DATE)	
	
	DECLARE @doc_return AS TABLE (czrc_id INT, fiscal_num INT, cr_id INT, fa_id INT, fiscal_dt DATE)
	DECLARE @detail_tab AS TABLE (
	        	operation_type CHAR(1),
	        	oczdi_id INT,
	        	gtin01 VARCHAR(14),
	        	serial21 NVARCHAR(20),
	        	fiscal_num INT,
	        	cr_id INT,
	        	fa_id INT,
	        	fiscal_dt DATE,
	        	price_with_vat NUMERIC(9, 2)
	        )
	
	SELECT	@error_text = CASE 
	      	                   WHEN ISNULL(d.gtin01, '') = '' OR LEN(d.gtin01) < 14 THEN 'Есть строка с не валидным gtin ' + ISNULL(d.gtin01, 'null') +
	      	                        ' в строке номер ' + CAST(d.id AS VARCHAR(10))
	      	                   WHEN ISNULL(d.serial21, '') = '' OR LEN(d.serial21) < 6 THEN 'Есть строка с не валидным serial ' + ISNULL(d.serial21, 'null') +
	      	                        ' в строке номер ' + CAST(d.id AS VARCHAR(10))
	      	                   WHEN ISNULL(d.fiscal_num, 0) = 0 THEN 'Есть строка с не валидным фискальным номером ' + CAST(d.fiscal_num AS VARCHAR(10)) +
	      	                        ' в строке номер ' + CAST(d.id AS VARCHAR(10))
	      	                   WHEN ISNULL(d.cr_name, '') = '' OR LEN(d.cr_name) < 3 THEN 'Есть строка с не валидным номером кассы ' + ISNULL(d.cr_name, 'null') 
	      	                        + ' в строке номер ' + CAST(d.id AS VARCHAR(10))
	      	                   WHEN ISNULL(d.fa_name, '') = '' OR LEN(d.fa_name) < 3 THEN 'Есть строка с не валидным номером фискального регистратора ' + ISNULL(
	      	                                                                                                                                                    d.fa_name, 
	      	                                                                                                                                                    'null') 
	      	                        + ' в строке номер ' + CAST(d.id AS VARCHAR(10))
	      	                   WHEN d.fiscal_dt IS NULL OR d.fiscal_dt < DATEFROMPARTS(2020, 1, 1) THEN 'Есть строка с не валидной датой фискализвации ' + CAST(d.fiscal_dt AS VARCHAR(20)) 
	      	                        + ' в строке номер ' + CAST(d.id AS VARCHAR(10))
	      	                   WHEN ISNULL(d.price_with_vat, 0) = 0 THEN 'Есть строка с не валидной цоной ' + CAST(d.price_with_vat AS VARCHAR(10)) +
	      	                        ' в строке номер ' + CAST(d.id AS VARCHAR(10))
	      	                   ELSE NULL
	      	              END
	FROM	@detail d
	WHERE	ISNULL(d.gtin01, '') = ''
			OR	LEN(d.gtin01) < 14
			OR	ISNULL(d.serial21, '') = ''
			OR	LEN(d.serial21) < 6
			OR	ISNULL(d.fiscal_num, 0) = 0
			OR	ISNULL(d.cr_name, '') = ''
			OR	LEN(d.cr_name) < 3
			OR	ISNULL(d.fa_name, '') = ''
			OR	LEN(d.fa_name) < 3
			OR	d.fiscal_dt IS NULL
			OR	d.fiscal_dt < DATEFROMPARTS(2020, 1, 1)
			OR	ISNULL(d.price_with_vat, 0) = 0
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	INSERT INTO RefBook.CashReg
		(
			cr_reg_num
		)
	SELECT	DISTINCT d.cr_name
	FROM	@detail d
	WHERE	NOT EXISTS (
	     		SELECT	1
	     		FROM	RefBook.CashReg cr
	     		WHERE	cr.cr_reg_num = d.cr_name
	     	)
	
	INSERT INTO RefBook.FiscalAccumulator
		(
			fa_number
		)
	SELECT	DISTINCT d.fa_name
	FROM	@detail d
	WHERE	NOT EXISTS (
	     		SELECT	1
	     		FROM	RefBook.FiscalAccumulator fa
	     		WHERE	fa.fa_number = d.fa_name
	     	)
	
	
	INSERT INTO @detail_tab
		(
			operation_type,
			oczdi_id,
			gtin01,
			serial21,
			fiscal_num,
			cr_id,
			fa_id,
			fiscal_dt,
			price_with_vat
		)
	SELECT	DISTINCT
	      	d.operation_type,
			oczdi.oczdi_id,
			d.gtin01,
			d.serial21,
			d.fiscal_num,
			cr.cr_id,
			fa.fa_id,
			d.fiscal_dt,
			d.price_with_vat
	FROM	@detail d   
			LEFT JOIN	Manufactory.OrderChestnyZnakDetailItem oczdi
				ON	oczdi.gtin01 = d.gtin01
				AND	oczdi.serial21 = d.serial21   
			INNER JOIN	RefBook.CashReg cr
				ON	cr.cr_reg_num = d.cr_name   
			INNER JOIN	RefBook.FiscalAccumulator fa
				ON	fa.fa_number = d.fa_name   
			LEFT JOIN	Manufactory.ChestnyZnakOutCirculation czoc
				ON	d.operation_type = 'O'
				AND	czoc.fiscal_dt = d.fiscal_dt
				AND	czoc.fiscal_num = d.fiscal_num
				AND czoc.fa_id   = fa.fa_id
				AND czoc.cr_id   = cr.cr_id
			LEFT JOIN	Manufactory.ChestnyZnakReturnCirculation czrc
				ON	d.operation_type = 'R'
				AND	czrc.fiscal_dt = d.fiscal_dt
				AND	czrc.fiscal_num = d.fiscal_num   
				AND czrc.fa_id   = fa.fa_id
				AND czrc.cr_id   = cr.cr_id
	WHERE	czoc.czoc_id IS NULL
			AND	czrc.czrc_id IS NULL
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	@detail_tab do
	   )
	BEGIN
	    RAISERROR('Все коды уже обработаны', 16, 1)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION 	
		
		INSERT INTO Manufactory.ChestnyZnakReturnCirculation
			(
				employee_id,
				dt_create,
				fiscal_num,
				cr_id,
				fa_id,
				fiscal_dt,
				dt_send
			)OUTPUT	INSERTED.czrc_id,
			 		INSERTED.fiscal_num,
			 		INSERTED.cr_id,
			 		INSERTED.fa_id,
			 		INSERTED.fiscal_dt
			 INTO	@doc_return (
			 		czrc_id,
			 		fiscal_num,
			 		cr_id,
			 		fa_id,
			 		fiscal_dt
			 	)
		SELECT	@employee_id,
				@dt,
				dt.fiscal_num,
				dt.cr_id,
				dt.fa_id,
				dt.fiscal_dt,
				CASE 
				     WHEN MAX(dt.oczdi_id) IS NULL THEN @dt
				     ELSE NULL
				END
		FROM	@detail_tab dt
		WHERE	dt.operation_type = 'R'
		GROUP BY
			dt.fiscal_num,
			dt.cr_id,
			dt.fa_id,
			dt.fiscal_dt
		ORDER BY
			dt.fiscal_dt ASC,
			dt.fiscal_num
		
		INSERT INTO Manufactory.ChestnyZnakReturnCirculationDetail
			(
				czrc_id,
				oczdi_id,
				price_with_vat
			)
		SELECT	dot.czrc_id,
				do.oczdi_id,
				do.price_with_vat
		FROM	@detail_tab do   
				INNER JOIN	@doc_return dot
					ON	dot.fiscal_dt = do.fiscal_dt
					AND	dot.fiscal_num = do.fiscal_num
					AND	dot.cr_id = do.cr_id
					AND	dot.fa_id = do.fa_id
		WHERE	do.operation_type = 'R'
				AND	do.oczdi_id IS NOT NULL
		
		
		INSERT INTO Manufactory.ChestnyZnakReturnCirculationDetailFail
			(
				czrc_id,
				gtin01,
				serial21,
				price_with_vat
			)
		SELECT	dot.czrc_id,
				do.gtin01,
				do.serial21,
				do.price_with_vat
		FROM	@detail_tab do   
				INNER JOIN	@doc_return dot
					ON	dot.fiscal_dt = do.fiscal_dt
					AND	dot.fiscal_num = do.fiscal_num
					AND	dot.cr_id = do.cr_id
					AND	dot.fa_id = do.fa_id
		WHERE	do.operation_type = 'R'
				AND	do.oczdi_id IS NULL	
		
		INSERT INTO Manufactory.ChestnyZnakOutCirculation
			(
				employee_id,
				dt_create,
				fiscal_num,
				cr_id,
				fa_id,
				fiscal_dt,
				dt_send
			)OUTPUT	INSERTED.czoc_id,
			 		INSERTED.fiscal_num,
			 		INSERTED.cr_id,
			 		INSERTED.fa_id,
			 		INSERTED.fiscal_dt
			 INTO	@doc_out (
			 		czoc_id,
			 		fiscal_num,
			 		cr_id,
			 		fa_id,
			 		fiscal_dt
			 	)
		SELECT	@employee_id,
				@dt,
				dt.fiscal_num,
				dt.cr_id,
				dt.fa_id,
				dt.fiscal_dt,
				CASE 
				     WHEN MAX(dt.oczdi_id) IS NULL THEN @dt
				     ELSE NULL
				END
		FROM	@detail_tab dt
		WHERE	dt.operation_type = 'O'
		GROUP BY
			dt.fiscal_num,
			dt.cr_id,
			dt.fa_id,
			dt.fiscal_dt
		ORDER BY
			dt.fiscal_dt ASC,
			dt.fiscal_num
		
		INSERT INTO Manufactory.ChestnyZnakOutCirculationDetail
			(
				czoc_id,
				oczdi_id,
				price_with_vat
			)
		SELECT	dot.czoc_id,
				do.oczdi_id,
				do.price_with_vat
		FROM	@detail_tab do   
				INNER JOIN	@doc_out dot
					ON	dot.fiscal_dt = do.fiscal_dt
					AND	dot.fiscal_num = do.fiscal_num
					AND	dot.cr_id = do.cr_id
					AND	dot.fa_id = do.fa_id
		WHERE	do.operation_type = 'O'
				AND	do.oczdi_id IS NOT NULL
		
		
		INSERT INTO Manufactory.ChestnyZnakOutCirculationDetailFail
			(
				czoc_id,
				gtin01,
				serial21,
				price_with_vat
			)
		SELECT	dot.czoc_id,
				do.gtin01,
				do.serial21,
				do.price_with_vat
		FROM	@detail_tab do   
				INNER JOIN	@doc_out dot
					ON	dot.fiscal_dt = do.fiscal_dt
					AND	dot.fiscal_num = do.fiscal_num
					AND	dot.cr_id = do.cr_id
					AND	dot.fa_id = do.fa_id
		WHERE	do.operation_type = 'O'
				AND	do.oczdi_id IS NULL
		
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