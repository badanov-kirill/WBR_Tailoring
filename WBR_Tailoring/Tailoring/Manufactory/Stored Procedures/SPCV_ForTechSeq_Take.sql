CREATE PROCEDURE [Manufactory].[SPCV_ForTechSeq_Take]
	@employee_id INT
AS
	SET NOCOUNT ON
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @spcvfts_id INT
	
	
	SELECT	@spcvfts_id = sfts.spcvfts_id
	FROM	Manufactory.SPCV_ForTechSeq sfts
	WHERE	sfts.employee_id = @employee_id
			AND	sfts.finish_dt IS NULL
	
	BEGIN TRY
		IF @spcvfts_id IS NULL
		BEGIN
		    UPDATE	v
		    SET 	v.employee_id = @employee_id,
		    		v.start_dt = @dt,
		    		@spcvfts_id = v.spcvfts_id
		    FROM	(
		        		SELECT	TOP(1) sfts.employee_id,
		        				sfts.start_dt,
		        				sfts.spcvfts_id
		        		FROM	Manufactory.SPCV_ForTechSeq sfts
		        		WHERE	sfts.start_dt IS NULL
		        		ORDER BY
		        			sfts.qp_id ASC,
		        			sfts.proirity_level DESC,
		        			--CASE 
		        			--     WHEN sfts.base_technolog_employee_id = @employee_id THEN 0
		        			--     ELSE 1
		        			--END ASC,
		        			sfts.plan_dt ASC
		        	) v
		END
		
		SELECT	sfts.spcvfts_id,
				sk.sketch_id,
				pa.sa + pan.sa sa,
				an.art_name,
				sj.subject_name,
				sk.constructor_employee_id,
				sk.create_employee_id,
				sk.ct_id,
				ct.ct_name,
				spcv.spcv_id
		FROM	Manufactory.SPCV_ForTechSeq sfts   
				INNER JOIN	Planing.SketchPlanColorVariant spcv
					ON	spcv.spcv_id = sfts.spcv_id   
				INNER JOIN	Planing.SketchPlan sp
					ON	sp.sp_id = spcv.sp_id   
				INNER JOIN	Products.Sketch sk
					ON	sk.sketch_id = sp.sketch_id   
				INNER JOIN	Products.ArtName an
					ON	an.art_name_id = sk.art_name_id   
				INNER JOIN	Products.[Subject] sj
					ON	sj.subject_id = sk.subject_id   
				LEFT JOIN	Material.ClothType ct
					ON	ct.ct_id = sk.ct_id
				LEFT JOIN Products.ProdArticleNomenclature pan
				INNER JOIN Products.ProdArticle pa
					ON pa.pa_id = pan.pa_id
					ON pan.pan_id = spcv.pan_id
				
		WHERE	sfts.spcvfts_id = @spcvfts_id
		
		SELECT	ts.operation_range,
				ts.ct_id,
				ct.ct_name,
				ts.ta_id,
				ta.ta_name            ta,
				ts.element_id,
				e.element_name        element,
				ts.equipment_id,
				eq.equipment_name     equipment,
				ts.dr_id,
				ts.dc_id,
				ts.operation_value,
				ts.discharge_id,
				ts.rotaiting,
				ts.dc_coefficient,
				cd.comment,
				ts.operation_time
		FROM	Manufactory.SPCV_ForTechSeq sfts   
				INNER JOIN	Planing.SketchPlanColorVariant spcv
					ON	spcv.spcv_id = sfts.spcv_id   
				INNER JOIN	Planing.SketchPlan sp
					ON	sp.sp_id = spcv.sp_id   
				INNER JOIN	Products.TechnologicalSequence ts
					ON	ts.sketch_id = sp.sketch_id   
				INNER JOIN	Material.ClothType ct
					ON	ct.ct_id = ts.ct_id   
				INNER JOIN	Technology.TechAction ta
					ON	ta.ta_id = ts.ta_id   
				INNER JOIN	Technology.Element e
					ON	e.element_id = ts.element_id   
				INNER JOIN	Technology.Equipment eq
					ON	eq.equipment_id = ts.equipment_id   
				INNER JOIN	Technology.CommentDict cd
					ON	cd.comment_id = ts.comment_id
		WHERE	sfts.spcvfts_id = @spcvfts_id
		ORDER BY
			ts.operation_range
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