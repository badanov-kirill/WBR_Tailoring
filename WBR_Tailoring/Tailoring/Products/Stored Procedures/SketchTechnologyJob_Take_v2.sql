CREATE PROCEDURE [Products].[SketchTechnologyJob_Take_v2]
	@employee_id INT,
	@ct_id INT = NULL,
	@stjt_id TINYINT = 1
AS
	SET NOCOUNT ON
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @stj_id INT
	
	SELECT	@stj_id = stj.stj_id
	FROM	Products.SketchTechnologyJob stj
	WHERE	stj.end_dt IS NULL
			AND	stj.begin_employee_id = @employee_id
	
	BEGIN TRY
		IF @stj_id IS NULL
		BEGIN
		    UPDATE	vt
		    SET 	begin_dt              = @dt,
		    		begin_employee_id     = @employee_id,
		    		@stj_id               = vt.stj_id
		    FROM	(
		        		SELECT	TOP(1) stj.stj_id,
		        				stj.begin_dt,
		        				stj.begin_employee_id
		        		FROM	Products.SketchTechnologyJob stj   
		        				INNER JOIN	Products.Sketch s
		        					ON	s.sketch_id = stj.sketch_id
		        		WHERE	stj.begin_employee_id IS NULL
		        				AND	stj.end_dt IS NULL
		        				AND (@ct_id IS NULL OR s.ct_id = @ct_id)
		        				AND stj.stjt_id = @stjt_id
		        				AND (s.technology_employee_id = @employee_id OR stj.stjt_id = 2)
		        				AND	(s.ss_id IN (10, 14, 15, 16, 17, 18, 19) OR stj.stjt_id = 2)
		        		ORDER BY
		        			CASE 
		        			     WHEN stj.stjt_id = 2 THEN 0
		        			     ELSE 1
		        			END ASC,
		        			stj.qp_id ASC,
		        			s.qp_id ASC,
		        			stj.stj_id ASC
		        	) vt
		END
		
		SELECT	stj.stj_id,
				sk.sketch_id,
				ISNULL(sk.pattern_name, sk.sa_local) sa,
				an.art_name,
				sj.subject_name,
				sk.constructor_employee_id,
				sk.create_employee_id,
				sk.ct_id,
				ct.ct_name,
				stjc.comment,
				stjt.stjt_name
		FROM	Products.SketchTechnologyJob stj   
				INNER JOIN	Products.Sketch sk
					ON	sk.sketch_id = stj.sketch_id   
				INNER JOIN	Products.ArtName an
					ON	an.art_name_id = sk.art_name_id   
				INNER JOIN	Products.[Subject] sj
					ON	sj.subject_id = sk.subject_id   
				LEFT JOIN	Material.ClothType ct
					ON	ct.ct_id = sk.ct_id
				LEFT JOIN Products.SketchTechnologyJobComment stjc
					ON stjc.stj_id = stj.stj_id
				INNER JOIN Products.SketchTechnologyJobType stjt
					ON stjt.stjt_id = stj.stjt_id
		WHERE	stj.stj_id = @stj_id
		
		SELECT	ts.operation_range,
				ts.ct_id,
				ct.ct_name,
				ts.ta_id,
				ta.ta_name ta,
				ts.element_id,
				e.element_name element,
				ts.equipment_id,
				eq.equipment_name equipment,
				ts.dr_id,
				ts.dc_id,
				ts.operation_value,
				ts.discharge_id,
				ts.rotaiting,
				ts.dc_coefficient,
				cd.comment,
				ts.operation_time
		FROM	Products.SketchTechnologyJob stj   
				INNER JOIN	Products.TechnologicalSequence ts
					ON	ts.sketch_id = stj.sketch_id   
				INNER JOIN	Material.ClothType ct
					ON	ct.ct_id = ts.ct_id   
				INNER JOIN	Technology.TechAction ta
					ON	ta.ta_id = ts.ta_id   
				INNER JOIN	Technology.Element e
					ON	e.element_id = ts.element_id   
				INNER JOIN	Technology.Equipment eq
					ON	eq.equipment_id = ts.equipment_id
				INNER JOIN Technology.CommentDict cd
					ON cd.comment_id = ts.comment_id
		WHERE	stj.stj_id = @stj_id
		ORDER BY ts.operation_range
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