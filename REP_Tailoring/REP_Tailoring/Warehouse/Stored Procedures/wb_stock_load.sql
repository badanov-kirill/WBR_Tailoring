CREATE PROCEDURE [Warehouse].[wb_stock_load]
	@period_dt DATE,
	@detail Warehouse.wb_stock_type READONLY
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	
	DECLARE @data_tab TABLE (
	        	subject_name VARCHAR(50) NULL,
	        	nm_id INT NOT NULL,
	        	brand_name VARCHAR(50) NULL,
	        	sa_name VARCHAR(36) NULL,
	        	ts_name VARCHAR(15) NULL,
	        	barcode VARCHAR(30) NULL,
	        	office_name VARCHAR(50) NULL,
	        	quantity SMALLINT NOT NULL,
	        	quantity_full SMALLINT NOT NULL,
	        	quantity_not_in_orders SMALLINT NOT NULL,
	        	in_way_to_client SMALLINT NOT NULL,
	        	in_way_from_client SMALLINT NOT NULL,
	        	days_on_site SMALLINT NOT NULL,
	        	subject_id SMALLINT NULL,
	        	brand_id SMALLINT NULL,
	        	sa_id INT NULL,
	        	ts_id SMALLINT NULL,
	        	barcode_id INT NULL,
	        	doc_type_id SMALLINT NULL,
	        	office_id SMALLINT NULL
	        )
	
	INSERT INTO @data_tab
		(
			subject_name,
			nm_id,
			brand_name,
			sa_name,
			ts_name,
			barcode,
			office_name,
			quantity,
			quantity_full,
			quantity_not_in_orders,
			in_way_to_client,
			in_way_from_client,
			days_on_site
		)
	SELECT	ISNULL(d.subject_name, '')     subject_name,
			d.nm_id,
			ISNULL(d.brand_name, '')       brand_name,
			ISNULL(d.sa_name, '')          sa_name,
			ISNULL(d.ts_name, '')          ts_name,
			ISNULL(d.barcode, '')          barcode,
			ISNULL(d.office_name, '')      office_name,
			d.quantity,
			d.quantity_full,
			d.quantity_not_in_orders,
			d.in_way_to_client,
			d.in_way_from_client,
			d.days_on_site
	FROM	@detail                        d
	
	BEGIN TRY
		INSERT INTO Products.Subjects
			(
				subject_name
			)
		SELECT	DISTINCT dt.subject_name
		FROM	@data_tab dt
		WHERE	NOT EXISTS (
		     		SELECT	1
		     		FROM	Products.Subjects dc
		     		WHERE	dc.subject_name = dt.subject_name
		     	)
		
		INSERT INTO Products.Brands
			(
				brand_name
			)
		SELECT	DISTINCT dt.brand_name
		FROM	@data_tab dt
		WHERE	NOT EXISTS (
		     		SELECT	1
		     		FROM	Products.Brands dc
		     		WHERE	dc.brand_name = dt.brand_name
		     	)
		
		INSERT INTO Products.SupplierArticle
			(
				sa_name
			)
		SELECT	DISTINCT dt.sa_name
		FROM	@data_tab dt
		WHERE	NOT EXISTS (
		     		SELECT	1
		     		FROM	Products.SupplierArticle dc
		     		WHERE	dc.sa_name = dt.sa_name
		     	)
		
		INSERT INTO Products.TechSize
			(
				ts_name
			)
		SELECT	DISTINCT dt.ts_name
		FROM	@data_tab dt
		WHERE	NOT EXISTS (
		     		SELECT	1
		     		FROM	Products.TechSize dc
		     		WHERE	dc.ts_name = dt.ts_name
		     	)
		
		INSERT INTO Products.Barcodes
			(
				barcode
			)
		SELECT	DISTINCT dt.barcode
		FROM	@data_tab dt
		WHERE	NOT EXISTS (
		     		SELECT	1
		     		FROM	Products.Barcodes dc
		     		WHERE	dc.barcode = dt.barcode
		     	)
		
		INSERT INTO RefBook.Offices
			(
				office_name
			)
		SELECT	DISTINCT dt.office_name
		FROM	@data_tab dt
		WHERE	NOT EXISTS (
		     		SELECT	1
		     		FROM	RefBook.Offices dc
		     		WHERE	dc.office_name = dt.office_name
		     	)
		
		UPDATE	dt
		SET 	subject_id = sj.subject_id,
				brand_id = br.brand_id,
				sa_id = sa.sa_id,
				ts_id = ts.ts_id,
				barcode_id = bc.barcode_id,
				office_id = o.office_id
		FROM	@data_tab dt
				INNER JOIN	Products.Barcodes bc
					ON	bc.barcode = dt.barcode
				INNER JOIN	Products.Brands br
					ON	br.brand_name = dt.brand_name
				INNER JOIN	Products.Subjects sj
					ON	sj.subject_name = dt.subject_name
				INNER JOIN	Products.SupplierArticle sa
					ON	sa.sa_name = dt.sa_name
				INNER JOIN	Products.TechSize ts
					ON	ts.ts_name = dt.ts_name
				INNER JOIN	RefBook.Offices o
					ON	o.office_name = dt.office_name
		
		
		DELETE	
		FROM	Warehouse.wb_stock
		
		INSERT INTO Warehouse.wb_stock
			(
				period_dt,
				subject_id,
				nm_id,
				brand_id,
				sa_id,
				ts_id,
				barcode_id,
				office_id,
				quantity,
				quantity_full,
				quantity_not_in_orders,
				in_way_to_client,
				in_way_from_client,
				days_on_site
			)
		SELECT	@period_dt,
				dt.subject_id,
				dt.nm_id,
				dt.brand_id,
				dt.sa_id,
				dt.ts_id,
				dt.barcode_id,
				dt.office_id,
				dt.quantity,
				dt.quantity_full,
				dt.quantity_not_in_orders,
				dt.in_way_to_client,
				dt.in_way_from_client,
				dt.days_on_site
		FROM	@data_tab dt
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