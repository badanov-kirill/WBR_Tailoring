CREATE PROCEDURE [Planing].[PlanShipping_GetOpened]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	ps.ps_id,
			ps.src_office_id,
			sos.office_name                  src_office_name,
			ps.dst_office_id,
			dos.office_name                  dst_office_name,
			CAST(ps.plan_dt AS DATETIME)     plan_dt,
			permissible_weight,
			FORMAT(CAST(v.gross_mass AS DECIMAL(10, 1)) / 1000000, '0.0') mass_tonn
	FROM	Planing.PlanShipping ps   
			INNER JOIN	Settings.OfficeSetting sos
				ON	sos.office_id = ps.src_office_id   
			INNER JOIN	Settings.OfficeSetting dos
				ON	dos.office_id = ps.dst_office_id   
			LEFT JOIN	(SELECT	psd.ps_id,
			    	    	 		SUM(gross_mass) gross_mass
			    	    	 FROM	Planing.PlanShippingDetail psd
			    	    	 GROUP BY
			    	    	 	psd.ps_id)v
				ON	v.ps_id = ps.ps_id
	WHERE	ps.close_dt IS                   NULL
	ORDER BY ps.plan_dt ASC