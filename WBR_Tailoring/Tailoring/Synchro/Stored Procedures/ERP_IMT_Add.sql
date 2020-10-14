CREATE PROCEDURE [Synchro].[ERP_IMT_Add]
	@imt_id INT,
	@sa VARCHAR(36),
	@brand_id INT,
	@collection_id INT,
	@season_id INT,
	@kind_id INT,
	@subject_id INT,
	@style_id INT,
	@vc_log_id VARCHAR(20),
	@descr VARCHAR(1000)
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @log_id BIGINT = CAST(@vc_log_id AS BIGINT)
	DECLARE @is_tailoring BIT = 0
	DECLARE @sketch_id INT
	DECLARE @local_brand_id INT
	DECLARE @local_subject_id INT
	DECLARE @local_collection_id INT
	DECLARE @local_season_id INT
	DECLARE @local_kind_id INT
	DECLARE @local_style_id INT
	DECLARE @dt DATETIME2(0) = GETDATE()
	
	IF EXISTS (
	   	SELECT	1
	   	FROM	Products.ERP_IMT_Del eid
	   	WHERE	eid.imt_id = @imt_id
	   )
	   OR EXISTS(
	      	SELECT	1
	      	FROM	Products.ERP_IMT_ForMapping eifm
	      	WHERE	eifm.imt_id = @imt_id
	      )
	   OR EXISTS (
	      	SELECT	1
	      	FROM	Products.ERP_IMT_Sketch eis
	      	WHERE	eis.imt_id = @imt_id
	   )
	   OR EXISTS (
	      	SELECT	1
	      	FROM	Products.ProdArticle pa
	      	WHERE	pa.imt_id = @imt_id
	      )
	BEGIN
	    RETURN
	END 	
		
	SELECT	@local_brand_id = b.brand_id,
	   		@is_tailoring = 1
	FROM	Products.Brand b
	WHERE	b.erp_id = @brand_id
	
	
	IF @is_tailoring = 1
	BEGIN
	    
	    SELECT	@local_subject_id = s.subject_id
	    FROM	Products.[Subject] s
	    WHERE	s.erp_id = @subject_id
	    
	    SELECT	TOP(1) @sketch_id = s.sketch_id
	    FROM	Products.Sketch s
	    WHERE	@sa LIKE '%' + s.sa + '%'
	    		AND	s.brand_id = @local_brand_id
	    		AND	s.subject_id = @local_subject_id
	    ORDER BY
	    	s.sketch_id DESC
	    	
	    IF @sketch_id IS NULL
	    BEGIN
	    	SELECT	TOP(1) @sketch_id = s.sketch_id
			FROM	Products.Sketch s
			WHERE	@sa LIKE '%' + s.sa + '%'
	    			AND	s.brand_id = @local_brand_id
			ORDER BY
	    		s.sketch_id DESC
	    END	    
	    
	    SELECT	@local_collection_id = c.collection_id
	    FROM	Products.[Collection] c
	    WHERE	c.erp_id = @collection_id
	    
	    SELECT	@local_season_id = s.season_id
	    FROM	Products.Season s
	    WHERE	s.erp_id = @season_id
	    
	    SELECT	@local_kind_id = k.kind_id
	    FROM	Products.Kind k
	    WHERE	k.erp_id = @kind_id
	    
	    SELECT	@local_style_id = s.style_id
	    FROM	Products.Style s
	    WHERE	s.erp_id = @style_id
	END
		
	BEGIN TRY
		BEGIN TRANSACTION 
		IF @is_tailoring = 1
		BEGIN
		    IF @sketch_id IS NOT NULL
		    BEGIN
		        INSERT INTO Products.ERP_IMT_Sketch
		        	(
		        		imt_id,
		        		sketch_id,
		        		sa,
		        		dt,
		        		employee_id
		        	)
		        SELECT	@imt_id,
		        		@sketch_id,
		        		@sa,
		        		@dt,
		        		1
		        WHERE	NOT EXISTS (
		             		SELECT	1
		             		FROM	Products.ERP_IMT_Sketch eis
		             		WHERE	eis.imt_id = @imt_id
		             	)
		    END
		    ELSE
		    BEGIN
		        INSERT INTO Products.ERP_IMT_ForMapping
		        	(
		        		imt_id,
		        		descr,
		        		sa,
		        		brand_id,
		        		collection_id,
		        		season_id,
		        		kind_id,
		        		subject_id,
		        		style_id,
		        		dt
		        	)
		        SELECT	@imt_id,
		        		@descr,
		        		@sa,
		        		@local_brand_id,
		        		@local_collection_id,
		        		@local_season_id,
		        		@local_kind_id,
		        		@local_subject_id,
		        		@local_style_id,
		        		@dt
		        WHERE	NOT EXISTS(
		             		SELECT	1
		             		FROM	Products.ERP_IMT_ForMapping eifm
		             		WHERE	eifm.imt_id = @imt_id
		             	)
		    END;
		    
		    INSERT INTO Products.ERP_NM_Sketch
		    	(
		    		nm_id,
		    		imt_id,
		    		sa
		    	)
		    SELECT	en.nm_id,
		    		en.imt_id,
		    		en.sa
		    FROM	Synchro.ERP_NM en
		    WHERE	en.imt_id = @imt_id
		    		AND	NOT EXISTS (
		    		   		SELECT	1
		    		   		FROM	Products.ERP_NM_Sketch ens
		    		   		WHERE	ens.nm_id = en.nm_id
		    		   	)
		END
		
		
		UPDATE	Synchro.RV
		SET 	object_rv = CASE 
		    	                 WHEN object_rv > @log_id THEN object_rv
		    	                 ELSE @log_id
		    	            END,
				dt = @dt
		WHERE	ob_name = 'ERP_IMT'
		
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
	