CREATE PROCEDURE [Synchro].[DownloadUPD_Doc_Set]
	@doc_tab Synchro.DownloadUPD_DocType READONLY,
	@docdetail_tab Synchro.DownloadUPD_DocDetailType READONLY
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @out_tab TABLE(dud_id INT, esf_id INT)
	DECLARE @max_rv BIGINT
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	@doc_tab dt
	   )
	BEGIN
	    RETURN
	END
	
	INSERT INTO Synchro.DownloadUPD_DocType
		(
			upd_type
		)
	SELECT	DISTINCT dt.upd_type
	FROM	@doc_tab dt
	WHERE	NOT EXISTS (
	     		SELECT	1
	     		FROM	Synchro.DownloadUPD_DocType dudt
	     		WHERE	dudt.upd_type = dt.upd_type
	     	)
	
	;
	WITH cte AS (
		SELECT	LEFT(ddt.edo_item_name, 200) edo_item_name,
				LEFT(ddt.edo_item_article, 200) edo_item_article,
				LEFT(ddt.edo_item_code, 200) edo_item_code,
				LEFT(ddt.edo_item_spec, 200) edo_item_spec
		FROM	@docdetail_tab ddt   
				INNER JOIN	@doc_tab dt
					ON	dt.esf_id = ddt.esf_id
		WHERE	EXISTS (
		     		SELECT	1
		     		FROM	Suppliers.Supplier s
		     		WHERE	s.supplier_id = dt.supplier_id
		     	)
	)
	INSERT INTO Synchro.DownloadUPD_Item
		(
			item_name
		)
	SELECT	v.item_name
	FROM	(SELECT	c.edo_item_name     item_name
	    	 FROM	cte                 c
	    	UNION
	    	SELECT	c.edo_item_article     item_name
	    	FROM	cte                    c
	    	UNION
	    	SELECT	c.edo_item_code     item_name
	    	FROM	cte                 c
	    	UNION
	    	SELECT	c.edo_item_spec     item_name
	    	FROM	cte                 c)v
	WHERE	v.item_name IS NOT NULL
			AND	NOT EXISTS(
			   		SELECT	1
			   		FROM	Synchro.DownloadUPD_Item dui
			   		WHERE	dui.item_name = v.item_name
			   	)
	
	INSERT INTO Material.GTD
		(
			gtd_cod
		)
	SELECT	DISTINCT LEFT(ddt.edo_gtd, 30)
	FROM	@docdetail_tab ddt   
			INNER JOIN	@doc_tab dt
				ON	dt.esf_id = ddt.esf_id
	WHERE	ddt.edo_gtd IS NOT NULL
			AND	EXISTS (
			   		SELECT	1
			   		FROM	Suppliers.Supplier s
			   		WHERE	s.supplier_id = dt.supplier_id
			   	)
			AND	NOT EXISTS (
			   		SELECT	1
			   		FROM	Material.GTD g
			   		WHERE	g.gtd_cod = LEFT(ddt.edo_gtd, 30)
			   	)
	
	SELECT	@max_rv = MAX(dt.rv)
	FROM	@doc_tab dt
	
	
	BEGIN TRY
		BEGIN TRANSACTION 	
		
		UPDATE	dud
		SET 	dud.dt_proc = @dt
		FROM	Synchro.DownloadUPD_Doc dud
		WHERE	dud.dt_proc IS NULL
				AND	EXISTS(
				   		SELECT	1
				   		FROM	@doc_tab dt
				   		WHERE	dud.esf_id = dt.esf_id
				   	)
		
		INSERT INTO Synchro.DownloadUPD_Doc
			(
				esf_id,
				dudt_id,
				edo_doc_num,
				edo_doc_dt,
				supplier_id,
				suppliercontract_id,
				edo_sign_date,
				edo_revoke_date,
				rv,
				dt_load
			)OUTPUT	INSERTED.dud_id,
			 		INSERTED.esf_id
			 INTO	@out_tab (
			 		dud_id,
			 		esf_id
			 	)
		SELECT	dt.esf_id,
				dudt.dudt_id,
				dt.edo_doc_num,
				dt.edo_doc_dt,
				dt.supplier_id,
				dt.suppliercontract_id,
				dt.edo_sign_date,
				dt.edo_revoke_date,
				dt.rv,
				@dt
		FROM	@doc_tab dt   
				LEFT JOIN	Synchro.DownloadUPD_DocType dudt
					ON	dudt.upd_type = dt.upd_type
		WHERE	EXISTS (
		     		SELECT	1
		     		FROM	Suppliers.Supplier s
		     		WHERE	s.supplier_id = dt.supplier_id
		     	) 
		
		INSERT INTO Synchro.DownloadUPD_DocDetail
			(
				dud_id,
				esf_id,
				edo_pos_id,
				dui_id_item_name,
				edo_okei_code,
				okei_name,
				edo_quantity,
				edo_price,
				dui_id_item_article,
				dui_id_item_code,
				dui_id_item_spec,
				edo_amount_nds,
				edo_amount_with_nds,
				edo_amount_without_nds,
				edo_vat,
				gtd_id,
				edo_country_id
			)
		SELECT	ot.dud_id,
				ddt.esf_id,
				ddt.edo_pos_id,
				duin.dui_id     dui_id_item_name,
				ddt.edo_okei_code,
				ddt.okei_name,
				ddt.edo_quantity,
				ddt.edo_price,
				duia.dui_id     dui_id_item_article,
				duic.dui_id     dui_id_item_code,
				duis.dui_id     dui_id_item_spec,
				ddt.edo_amount_nds,
				ddt.edo_amount_with_nds,
				ddt.edo_amount_without_nds,
				ddt.edo_vat,
				g.gtd_id,
				ddt.edo_country_id
		FROM	@out_tab ot   
				INNER JOIN	@docdetail_tab ddt
					ON	ot.esf_id = ddt.esf_id   
				LEFT JOIN	Synchro.DownloadUPD_Item duin
					ON	duin.item_name = LEFT(ddt.edo_item_name,
				200)   
				LEFT JOIN	Synchro.DownloadUPD_Item duia
					ON	duia.item_name = LEFT(ddt.edo_item_article,
				200)   
				LEFT JOIN	Synchro.DownloadUPD_Item duic
					ON	duic.item_name = LEFT(ddt.edo_item_code,
				200)   
				LEFT JOIN	Synchro.DownloadUPD_Item duis
					ON	duis.item_name = LEFT(ddt.edo_item_spec,
				200)   
				LEFT JOIN	Material.GTD g
					ON	g.gtd_cod = LEFT(ddt.edo_gtd,
				30)
		
		UPDATE	Synchro.RV
		SET 	object_rv = @max_rv,
				dt = @dt
		WHERE	ob_name = 'ASTRA_UPD'
		
		
		
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
		
		
		RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess) WITH LOG;
	END CATCH 