CREATE PROCEDURE [SyncFinance].[SpecificationToContract_Set]
	@spec_tab SyncFinance.SpecificationToContractType READONLY,
	@spec_material_detail SyncFinance.SpecificationToContractDetailType READONLY,
	@spec_stuff_detail SyncFinance.SpecificationToContractDetailType READONLY,
	@spec_service_detail SyncFinance.SpecificationToContractDetailType READONLY
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	@spec_tab
	   )
	BEGIN
	    RETURN
	END
	
	IF (
	   	SELECT	COUNT(1)
	   	FROM	@spec_tab st
	   ) != (
	   	SELECT	COUNT(DISTINCT st.stc_id)
	   	FROM	@spec_tab st
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
		      	FROM	@spec_tab d
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
		      	FROM	@spec_material_detail d
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
		      	FROM	@spec_stuff_detail d
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
		      	FROM	@spec_stuff_detail d
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
		MERGE Material.SpecificationToContract t
		USING @spec_tab s
				ON t.stc_id = s.stc_id
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
		     		accept_dt = s.accept_dt,
		     		delay_day_count = s.delay_day_count,
		     		is_start_received = s.is_start_received,
		     		comment = s.comment,
		     		is_price_list = s.is_price_list,
		     		currency_id = s.currency_id,
		     		dt_calc_in = s.dt_calc_in
		WHEN NOT MATCHED THEN 
		     INSERT
		     	(
		     		stc_id,
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
		     		accept_dt,
		     		delay_day_count,
		     		is_start_received,
		     		comment,
		     		is_price_list,
		     		currency_id,
		     		dt_calc_in
		     	)
		     VALUES
		     	(
		     		s.stc_id,
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
		     		s.accept_dt,
		     		s.delay_day_count,
		     		s.is_start_received,
		     		s.comment,
		     		s.is_price_list,
		     		s.currency_id,
		     		s.dt_calc_in
		     	)
		     	OUTPUT s.sync_id, s.rv INTO @out_tab
		     (
		     	id,
		     	rv
		     );
		
		INSERT INTO History.SpecificationToContractLog
			(
				sct_id,
				dt,
				supplier_id,
				currency_id,
				employee_id,
				material_cnt,
				material_amount_sum,
				material_qty_sum
			)
		SELECT	st.stc_id,
				@dt,
				st.supplier_id,
				st.currency_id,
				st.employee_id,
				COUNT(1),
				SUM(stmd.amount),
				SUM(stmd.qty)
		FROM	@spec_tab st   
				LEFT JOIN	@spec_material_detail stmd
					ON	st.stc_id = stmd.stc_id
		GROUP BY
			st.stc_id,
			st.supplier_id,
			st.currency_id,
			st.employee_id
		
		;
		WITH cte_target AS (
			SELECT	stcmd.stcmd_id,
					stcmd.stc_id,
					stcmd.nomenclature_code,
					stcmd.nomenclature_name,
					stcmd.mat_id,
					stcmd.qty,
					stcmd.price,
					stcmd.nds,
					stcmd.amount,
					stcmd.okei_id,
					stcmd.receipt_dt,
					stcmd.days_before_pay,
					stcmd.plan_pay_dt,
					stcmd.price_with_vat
			FROM	Material.SpecificationToContractMaterialDetail stcmd
			WHERE	EXISTS(
			     		SELECT	1
			     		FROM	@spec_tab st
			     		WHERE	st.stc_id = stcmd.stc_id
			     	)
		)
		MERGE cte_target t
		USING @spec_material_detail s
				ON s.id = t.stcmd_id
		WHEN MATCHED THEN 
		     UPDATE	
		     SET 	stcmd_id              = s.id,
		     		stc_id                = s.stc_id,
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
		     		stcmd_id,
		     		stc_id,
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
		     		s.stc_id,
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
			SELECT	stcmd.stcsd_id,
					stcmd.stc_id,
					stcmd.nomenclature_code,
					stcmd.nomenclature_name,
					stcmd.stuff_model_id,
					stcmd.qty,
					stcmd.price,
					stcmd.nds,
					stcmd.amount,
					stcmd.okei_id,
					stcmd.receipt_dt,
					stcmd.days_before_pay,
					stcmd.plan_pay_dt,
					stcmd.price_with_vat
			FROM	Material.SpecificationToContractStuffDetail stcmd
			WHERE	EXISTS(
			     		SELECT	1
			     		FROM	@spec_tab st
			     		WHERE	st.stc_id = stcmd.stc_id
			     	)
		)
		MERGE cte_target t
		USING @spec_stuff_detail s
				ON s.id = t.stcsd_id
		WHEN MATCHED THEN 
		     UPDATE	
		     SET 	stcsd_id              = s.id,
		     		stc_id                = s.stc_id,
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
		     		stcsd_id,
		     		stc_id,
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
		     		s.stc_id,
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
			SELECT	stcmd.stcrsd_id,
					stcmd.stc_id,
					stcmd.nomenclature_code,
					stcmd.nomenclature_name,
					stcmd.rs_id,
					stcmd.qty,
					stcmd.price,
					stcmd.nds,
					stcmd.amount,
					stcmd.okei_id,
					stcmd.receipt_dt,
					stcmd.days_before_pay,
					stcmd.plan_pay_dt,
					stcmd.price_with_vat
			FROM	Material.SpecificationToContractRenderServiceDetail stcmd
			WHERE	EXISTS(
			     		SELECT	1
			     		FROM	@spec_tab st
			     		WHERE	st.stc_id = stcmd.stc_id
			     	)
		)
		MERGE cte_target t
		USING @spec_service_detail s
				ON s.id = t.stcrsd_id
		WHEN MATCHED THEN 
		     UPDATE	
		     SET 	stcrsd_id             = s.id,
		     		stc_id                = s.stc_id,
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
		     		stcrsd_id,
		     		stc_id,
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
		     		s.stc_id,
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