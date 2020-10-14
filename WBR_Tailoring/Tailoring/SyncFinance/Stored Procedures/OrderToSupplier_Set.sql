CREATE PROCEDURE [SyncFinance].[OrderToSupplier_Set]
	@ots_tab SyncFinance.OrderToSupplierType READONLY,
	@ots_material_detail SyncFinance.OrderToSupplierDetailType READONLY,
	@ots_stuff_detail   SyncFinance.OrderToSupplierDetailType READONLY,
	@ots_service_detail SyncFinance.OrderToSupplierDetailType READONLY
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	@ots_tab
	   )
	BEGIN
	    RETURN
	END
	
	IF (
	   	SELECT	COUNT(1)
	   	FROM	@ots_tab st
	   ) != (
	   	SELECT	COUNT(DISTINCT st.ots_id)
	   	FROM	@ots_tab st
	   )
	BEGIN
	    RAISERROR('Есть дубли документов в шапке', 16, 1)
	    RETURN
	END
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @out_tab TABLE (id INT, rv BIGINT)
	
	
	BEGIN TRY
		;
		MERGE Material.SpecificationTypeOfPayment t
		USING (
		      	SELECT	d.type_of_payment_id,
		      			MAX(d.type_of_payment_name) type_of_payment_name
		      	FROM	@ots_tab d
		      	WHERE	d.type_of_payment_id IS NOT NULL
		      			AND	d.type_of_payment_name IS NOT NULL
		      	GROUP BY
		      		d.type_of_payment_id
		      ) s
				ON t.type_of_payment_id = s.type_of_payment_id
		WHEN MATCHED AND t.type_of_payment_name != s.type_of_payment_name THEN 
		     UPDATE	
		     SET 	t.type_of_payment_name = s.type_of_payment_name
		WHEN NOT MATCHED THEN 
		     INSERT
		     	(
		     		type_of_payment_id,
		     		type_of_payment_name
		     	)
		     VALUES
		     	(
		     		s.type_of_payment_id,
		     		s.type_of_payment_name
		     	);
		
		;
		MERGE Material.SpecificationMaterial t
		USING (
		      	SELECT	d.tmc_id,
		      			MAX(d.tmc_name) tmc_name
		      	FROM	@ots_material_detail d
		      	WHERE	d.tmc_id IS NOT NULL
		      			AND	d.tmc_name IS NOT NULL
		      	GROUP BY
		      		d.tmc_id
		      ) s
				ON t.mat_id = s.tmc_id
		WHEN MATCHED AND t.mat_name != s.tmc_name THEN 
		     UPDATE	
		     SET 	t.mat_name = s.tmc_name
		WHEN NOT MATCHED THEN 
		     INSERT
		     	(
		     		mat_id,
		     		mat_name
		     	)
		     VALUES
		     	(
		     		s.tmc_id,
		     		s.tmc_name
		     	);
		
		;
		MERGE Material.SpecificationStuffModel t
		USING (
		      	SELECT	d.tmc_id,
		      			MAX(d.tmc_name) tmc_name
		      	FROM	@ots_stuff_detail d
		      	WHERE	d.tmc_id IS NOT NULL
		      			AND	d.tmc_name IS NOT NULL
		      	GROUP BY
		      		d.tmc_id
		      ) s
				ON t.stuff_model_id = s.tmc_id
		WHEN MATCHED AND t.stuff_model_name != s.tmc_name THEN 
		     UPDATE	
		     SET 	t.stuff_model_name = s.tmc_name
		WHEN NOT MATCHED THEN 
		     INSERT
		     	(
		     		stuff_model_id,
		     		stuff_model_name
		     	)
		     VALUES
		     	(
		     		s.tmc_id,
		     		s.tmc_name
		     	);
		
		;
		MERGE Material.SpecificationtRenderService t
		USING (
		      	SELECT	d.tmc_id,
		      			MAX(d.tmc_name) tmc_name
		      	FROM	@ots_service_detail d
		      	WHERE	d.tmc_id IS NOT NULL
		      			AND	d.tmc_name IS NOT NULL
		      	GROUP BY
		      		d.tmc_id
		      ) s
				ON t.rs_id = s.tmc_id
		WHEN MATCHED AND t.rs_name != s.tmc_name THEN 
		     UPDATE	
		     SET 	t.rs_name = s.tmc_name
		WHEN NOT MATCHED THEN 
		     INSERT
		     	(
		     		rs_id,
		     		rs_name
		     	)
		     VALUES
		     	(
		     		s.tmc_id,
		     		s.tmc_name
		     	);
		
		
		BEGIN TRANSACTION 
		
		;
		MERGE Material.OrderToSupplier t
		USING @ots_tab s
				ON t.ots_id = s.ots_id
		WHEN MATCHED THEN 
		     UPDATE	
		     SET 	doc_dt          = s.doc_dt,
		     		supplier_id     = s.supplier_id,
		     		suppliercontract_erp_id = s.supplier_contract_id,
		     		employee_id = s.employee_id,
		     		type_of_payment_id = s.type_of_payment_id,
		     		pay_prc1 = s.pay_prc1,
		     		pay_prc2 = s.pay_prc2,
		     		pay_prc3 = s.pay_prc3,
		     		pay_prc4 = s.pay_prc4,
		     		is_accounting_calendar = s.is_accounting_calendar,
		     		delay_day_count = s.delay_day_count,
		     		is_start_received = s.is_start_received,
		     		comment = s.comment,
		     		currency_id = s.currency_id
		WHEN NOT MATCHED THEN 
		     INSERT
		     	(
		     		ots_id,
		     		doc_dt,
		     		supplier_id,
		     		suppliercontract_erp_id,
		     		employee_id,
		     		type_of_payment_id,
		     		pay_prc1,
		     		pay_prc2,
		     		pay_prc3,
		     		pay_prc4,
		     		is_accounting_calendar,
		     		delay_day_count,
		     		is_start_received,
		     		comment,
		     		currency_id
		     	)
		     VALUES
		     	(
		     		s.ots_id,
		     		s.doc_dt,
		     		s.supplier_id,
		     		s.supplier_contract_id,
		     		s.employee_id,
		     		s.type_of_payment_id,
		     		s.pay_prc1,
		     		s.pay_prc2,
		     		s.pay_prc3,
		     		s.pay_prc4,
		     		s.is_accounting_calendar,
		     		s.delay_day_count,
		     		s.is_start_received,
		     		s.comment,
		     		s.currency_id
		     	)
		     	OUTPUT s.id, s.rv INTO @out_tab
		     (
		     	id,
		     	rv
		     );
		
		INSERT INTO History.OrderToSupplierLog
			(
				ots_id,
				dt,
				supplier_id,
				currency_id,
				employee_id,
				material_cnt,
				material_amount_sum,
				material_qty_sum
			)
		SELECT	st.ots_id,
				@dt,
				st.supplier_id,
				st.currency_id,
				st.employee_id,
				COUNT(1),
				SUM(stmd.amount),
				SUM(stmd.qty)
		FROM	@ots_tab st   
				LEFT JOIN	@ots_material_detail stmd
					ON	st.ots_id = stmd.ots_id
		GROUP BY
			st.ots_id,
			st.supplier_id,
			st.currency_id,
			st.employee_id
		
		;
		WITH cte_target AS (
			SELECT	otsmd.otsmd_id,
					otsmd.ots_id,
					otsmd.nomenclature_code,
					otsmd.nomenclature_name,
					otsmd.mat_id,
					otsmd.qty,
					otsmd.price,
					otsmd.nds,
					otsmd.amount,
					otsmd.okei_id,
					otsmd.receipt_dt,
					otsmd.days_before_pay,
					otsmd.plan_pay_dt,
					otsmd.price_with_vat
			FROM	Material.OrderToSupplierMaterialDetail otsmd
			WHERE	EXISTS(
			     		SELECT	1
			     		FROM	@ots_tab st
			     		WHERE	st.ots_id = otsmd.ots_id
			     	)
		)
		MERGE cte_target t
		USING @ots_material_detail s
				ON s.id = t.otsmd_id
		WHEN MATCHED THEN 
		     UPDATE	
		     SET 	otsmd_id              = s.id,
		     		ots_id                = s.ots_id,
		     		nomenclature_code     = s.nomenclature_code,
		     		nomenclature_name     = s.nomenclature_name,
		     		mat_id                = s.tmc_id,
		     		qty                   = s.qty,
		     		price                 = s.price,
		     		nds                   = s.vat_value,
		     		amount                = s.amount,
		     		okei_id               = s.okei_id,
		     		receipt_dt            = s.receipt_dt,
		     		days_before_pay       = s.days_before_pay,
		     		plan_pay_dt           = s.plan_pay_dt,
		     		price_with_vat        = s.price_with_vat
		WHEN NOT MATCHED BY TARGET THEN 
		     INSERT
		     	(
		     		otsmd_id,
		     		ots_id,
		     		nomenclature_code,
		     		nomenclature_name,
		     		mat_id,
		     		qty,
		     		price,
		     		nds,
		     		amount,
		     		okei_id,
		     		receipt_dt,
		     		days_before_pay,
		     		plan_pay_dt,
		     		price_with_vat
		     	)
		     VALUES
		     	(
		     		s.id,
		     		s.ots_id,
		     		s.nomenclature_code,
		     		s.nomenclature_name,
		     		s.tmc_id,
		     		s.qty,
		     		s.price,
		     		s.vat_value,
		     		s.amount,
		     		s.okei_id,
		     		s.receipt_dt,
		     		s.days_before_pay,
		     		s.plan_pay_dt,
		     		s.price_with_vat
		     	)
		WHEN NOT MATCHED BY SOURCE THEN 
		     DELETE	;
		
		
		;
		WITH cte_target AS (
			SELECT	otsrsd.otssd_id,
					otsrsd.ots_id,
					otsrsd.nomenclature_code,
					otsrsd.nomenclature_name,
					otsrsd.stuff_model_id,
					otsrsd.qty,
					otsrsd.price,
					otsrsd.nds,
					otsrsd.amount,
					otsrsd.okei_id,
					otsrsd.receipt_dt,
					otsrsd.days_before_pay,
					otsrsd.plan_pay_dt,
					otsrsd.price_with_vat
			FROM	Material.OrderToSupplierStuffDetail otsrsd
			WHERE	EXISTS(
			     		SELECT	1
			     		FROM	@ots_tab st
			     		WHERE	st.ots_id = otsrsd.ots_id
			     	)
		)
		MERGE cte_target t
		USING @ots_stuff_detail s
				ON s.id = t.otssd_id
		WHEN MATCHED THEN 
		     UPDATE	
		     SET 	otssd_id              = s.id,
		     		ots_id                = s.ots_id,
		     		nomenclature_code     = s.nomenclature_code,
		     		nomenclature_name     = s.nomenclature_name,
		     		stuff_model_id        = s.tmc_id,
		     		qty                   = s.qty,
		     		price                 = s.price,
		     		nds                   = s.vat_value,
		     		amount                = s.amount,
		     		okei_id               = s.okei_id,
		     		receipt_dt            = s.receipt_dt,
		     		days_before_pay       = s.days_before_pay,
		     		plan_pay_dt           = s.plan_pay_dt,
		     		price_with_vat        = s.price_with_vat
		WHEN NOT MATCHED BY TARGET THEN 
		     INSERT
		     	(
		     		otssd_id,
		     		ots_id,
		     		nomenclature_code,
		     		nomenclature_name,
		     		stuff_model_id,
		     		qty,
		     		price,
		     		nds,
		     		amount,
		     		okei_id,
		     		receipt_dt,
		     		days_before_pay,
		     		plan_pay_dt,
		     		price_with_vat
		     	)
		     VALUES
		     	(
		     		s.id,
		     		s.ots_id,
		     		s.nomenclature_code,
		     		s.nomenclature_name,
		     		s.tmc_id,
		     		s.qty,
		     		s.price,
		     		s.vat_value,
		     		s.amount,
		     		s.okei_id,
		     		s.receipt_dt,
		     		s.days_before_pay,
		     		s.plan_pay_dt,
		     		s.price_with_vat
		     	)
		WHEN NOT MATCHED BY SOURCE THEN 
		     DELETE	; 
		
		;
		WITH cte_target AS (
			SELECT	otsrsd.otsrsd_id,
					otsrsd.ots_id,
					otsrsd.nomenclature_code,
					otsrsd.nomenclature_name,
					otsrsd.rs_id,
					otsrsd.qty,
					otsrsd.price,
					otsrsd.nds,
					otsrsd.amount,
					otsrsd.okei_id,
					otsrsd.receipt_dt,
					otsrsd.days_before_pay,
					otsrsd.plan_pay_dt,
					otsrsd.price_with_vat
			FROM	Material.OrderToSupplierRenderServiceDetail otsrsd
			WHERE	EXISTS(
			     		SELECT	1
			     		FROM	@ots_tab st
			     		WHERE	st.ots_id = otsrsd.ots_id
			     	)
		)
		MERGE cte_target t
		USING @ots_service_detail s
				ON s.id = t.otsrsd_id
		WHEN MATCHED THEN 
		     UPDATE	
		     SET 	otsrsd_id             = s.id,
		     		ots_id                = s.ots_id,
		     		nomenclature_code     = s.nomenclature_code,
		     		nomenclature_name     = s.nomenclature_name,
		     		rs_id                 = s.tmc_id,
		     		qty                   = s.qty,
		     		price                 = s.price,
		     		nds                   = s.vat_value,
		     		amount                = s.amount,
		     		okei_id               = s.okei_id,
		     		receipt_dt            = s.receipt_dt,
		     		days_before_pay       = s.days_before_pay,
		     		plan_pay_dt           = s.plan_pay_dt,
		     		price_with_vat        = s.price_with_vat
		WHEN NOT MATCHED BY TARGET THEN 
		     INSERT
		     	(
		     		otsrsd_id,
		     		ots_id,
		     		nomenclature_code,
		     		nomenclature_name,
		     		rs_id,
		     		qty,
		     		price,
		     		nds,
		     		amount,
		     		okei_id,
		     		receipt_dt,
		     		days_before_pay,
		     		plan_pay_dt,
		     		price_with_vat
		     	)
		     VALUES
		     	(
		     		s.id,
		     		s.ots_id,
		     		s.nomenclature_code,
		     		s.nomenclature_name,
		     		s.tmc_id,
		     		s.qty,
		     		s.price,
		     		s.vat_value,
		     		s.amount,
		     		s.okei_id,
		     		s.receipt_dt,
		     		s.days_before_pay,
		     		s.plan_pay_dt,
		     		s.price_with_vat
		     	)
		WHEN NOT MATCHED BY SOURCE THEN 
		     DELETE	; 
		
		COMMIT TRANSACTION
		
		SELECT	ot.id,
				ot.rv
		FROM	@out_tab ot
		
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
		BEGIN
		    ROLLBACK TRANSACTION
		END
		
		DECLARE @ErrNum INT = ERROR_NUMBER();
		DECLARE @estate INT = ERROR_STATE();
		DECLARE @esev INT = ERROR_SEVERITY();
		DECLARE @Line INT = ERROR_LINE();
		DECLARE @Mess VARCHAR(MAX) = CHAR(10) + ISNULL('Процедура: ' + ERROR_PROCEDURE(), '') 
		        + CHAR(10) + ERROR_MESSAGE();
		
		
		RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess) WITH LOG;
	END CATCH
GO	