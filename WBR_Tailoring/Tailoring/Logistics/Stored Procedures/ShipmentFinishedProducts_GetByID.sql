CREATE PROCEDURE [Logistics].[ShipmentFinishedProducts_GetByID]
	@sfp_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	s.sfp_id,
			CAST(s.create_dt AS DATETIME) create_dt,
			s.create_employee_id,
			CAST(s.complite_dt AS DATETIME) close_dt,
			s.complite_employee_id,
			s.src_office_id,
			os.office_name           src_office_name,
			CAST(s.rv AS BIGINT)     rv_bigint,
			s.seal1,
			s.seal2,
			s.vehicle_id,
			v.brand_name             vehicle_brand_name,
			v.number_plate           vehicle_number_plate,
			s.driver_id,
			d.driver_name,
			s.towed_vehicle_id,
			tv.brand_name            towed_vehicle_brand_name,
			tv.number_plate          towed_vehicle_number_plate
	FROM	Logistics.ShipmentFinishedProducts s   
			LEFT JOIN	Settings.OfficeSetting os
				ON	s.src_office_id = os.office_id   
			LEFT JOIN	Logistics.Vehicle v
				ON	v.vehicle_id = s.vehicle_id   
			LEFT JOIN	Logistics.Driver d
				ON	d.driver_id = s.driver_id   
			LEFT JOIN	Logistics.Vehicle tv
				ON	tv.vehicle_id = s.towed_vehicle_id
	WHERE	s.sfp_id = @sfp_id
	
	SELECT	sfpd.transfer_box_id,
			CAST(sfpd.dt AS DATETIME) dt,
			sfpd.employee_id,
			es.employee_name
	FROM	Logistics.ShipmentFinishedProductsDetail sfpd   
			LEFT JOIN	Settings.EmployeeSetting es
				ON	es.employee_id = sfpd.employee_id
	WHERE	sfpd.sfp_id = @sfp_id
	
	SELECT	pbop.packing_box_id,
			os.office_name,
			sp.place_name,
			CAST(pb.start_packaging_dt AS DATETIME) start_packaging_dt,
			CAST(pb.close_dt AS DATETIME) close_dt,
			CAST(pbop.dt AS DATETIME)      place_dt,
			CAST(sfppb.dt AS DATETIME)     in_shipping_dt
	FROM	Logistics.PlanShipmentFinishedProductsPackingBox psfppb   
			INNER JOIN	Logistics.PackingBox pb
				ON	pb.packing_box_id = psfppb.packing_box_id   
			LEFT JOIN	Warehouse.PackingBoxOnPlace pbop
				ON	pbop.packing_box_id = pb.packing_box_id   
			LEFT JOIN	Warehouse.StoragePlace sp
				ON	sp.place_id = pbop.place_id   
			LEFT JOIN	Warehouse.ZoneOfResponse zor
				ON	zor.zor_id = sp.zor_id   
			LEFT JOIN	Settings.OfficeSetting os
				ON	os.office_id = zor.office_id   
			LEFT JOIN	Logistics.ShipmentFinishedProductsPackingBox sfppb
				ON	sfppb.packing_box_id = pb.packing_box_id
	WHERE	psfppb.sfp_id = @sfp_id
	
	SELECT	pa.sa + pan.sa     sa,
			ISNULL(s.imt_name, sj.subject_name_sf) imt_name,
			b.brand_name,
			ts.ts_name,
			e.ean              barcode,
			oczdi.gtin01,
			oczdi.serial21,
			oczdi.intrnal91,
			oczdi.intrnal92,
			oczdi.oczdi_id
	FROM	Logistics.ShipmentFinishedProductsChestnyZnak sfpcz   
			INNER JOIN	Manufactory.OrderChestnyZnakDetailItem oczdi
				ON	oczdi.oczdi_id = sfpcz.oczdi_id   
			INNER JOIN	Manufactory.ProductUnicCode_ChestnyZnakItem pucczi
				ON	pucczi.oczdi_id = oczdi.oczdi_id   
			INNER JOIN	Manufactory.ProductUnicCode puc
				ON	puc.product_unic_code = pucczi.product_unic_code   
			LEFT JOIN	Manufactory.EANCode e
				ON	e.pants_id = puc.pants_id   
			INNER JOIN	Products.ProdArticleNomenclatureTechSize pants
				ON	pants.pants_id = puc.pants_id   
			INNER JOIN	Products.ProdArticleNomenclature pan
				ON	pan.pan_id = pants.pan_id   
			INNER JOIN	Products.ProdArticle pa
				ON	pa.pa_id = pan.pa_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = pa.sketch_id   
			INNER JOIN	Products.[Subject] sj
				ON	sj.subject_id = s.subject_id   
			INNER JOIN	Products.Brand b
				ON	b.brand_id = pa.brand_id   
			INNER JOIN	Products.TechSize ts
				ON	ts.ts_id = pants.ts_id
	WHERE	sfpcz.sfp_id = @sfp_id
