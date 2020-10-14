CREATE PROCEDURE [Warehouse].[Inventory_GetByID]
	@inventory_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	i.inventory_id,
			CAST(i.plan_start_dt AS DATETIME) plan_start_dt,
			CAST(i.plan_finish_dt AS DATETIME) plan_finish_dt,
			CAST(i.create_dt AS DATETIME) create_dt,
			escr.employee_name               create_employee_name,
			it.it_name,
			i.it_id,
			i.comment,
			rmt.rmt_name,
			i.rmt_id,
			CAST(i.close_dt AS DATETIME)     close_dt,
			escl.employee_name               close_employee_name,
			i.lost_sum
	FROM	Warehouse.Inventory i   
			INNER JOIN	Warehouse.InventoryType it
				ON	it.it_id = i.it_id   
			INNER JOIN	Settings.EmployeeSetting escr
				ON	i.create_employee_id = escr.employee_id   
			LEFT JOIN	Settings.EmployeeSetting escl
				ON	i.close_employee_id = escl.employee_id   
			LEFT JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = i.rmt_id
	WHERE	i.inventory_id = @inventory_id
	
	SELECT	isr.shkrm_id,
			sma.amount * isr.stor_unit_residues_qty / sma.stor_unit_residues_qty amount,
			rmt.rmt_name,
			a.art_name,
			isr.okei_id,
			o.symbol okei_symbol,
			isr.qty,
			smsd.state_name,
			sms.state_id,
			sp.place_name + '(' + os.office_name + ')' place_name
	FROM	Warehouse.InventoryShkRM isr   
			INNER JOIN	Warehouse.SHKRawMaterialInfo smi
				ON	smi.shkrm_id = isr.shkrm_id   
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = smi.rmt_id   
			INNER JOIN	Material.Article a
				ON	a.art_id = smi.art_id   
			INNER JOIN	Qualifiers.OKEI o
				ON	o.okei_id = isr.okei_id   
			LEFT JOIN	Warehouse.SHKRawMaterialState sms   
			INNER JOIN	Warehouse.SHKRawMaterialStateDict smsd
				ON	smsd.state_id = sms.state_id
				ON	sms.shkrm_id = isr.shkrm_id   
			LEFT JOIN	Warehouse.SHKRawMaterialOnPlace smop   
			INNER JOIN	Warehouse.StoragePlace sp   
			INNER JOIN	Warehouse.ZoneOfResponse zor   
			INNER JOIN	Settings.OfficeSetting os
				ON	os.office_id = zor.office_id
				ON	zor.zor_id = sp.zor_id
				ON	sp.place_id = smop.place_id
				ON	smop.shkrm_id = isr.shkrm_id   
			INNER JOIN	Warehouse.SHKRawMaterialAmount sma
				ON	sma.shkrm_id = isr.shkrm_id
	WHERE	isr.inventory_id = @inventory_id
	
	SELECT	isr.shkrm_id,
			isr.amount     amount,
			rmt.rmt_name,
			a.art_name,
			isr.okei_id,
			o.symbol       okei_symbol,
			isr.qty,
			smsd.state_name,
			sms.state_id,
			sp.place_name + '(' + os.office_name + ')' place_name
	FROM	Warehouse.InventoryLostShkRM isr   
			INNER JOIN	Warehouse.SHKRawMaterialInfo smi
				ON	smi.shkrm_id = isr.shkrm_id   
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = smi.rmt_id   
			INNER JOIN	Material.Article a
				ON	a.art_id = smi.art_id   
			INNER JOIN	Qualifiers.OKEI o
				ON	o.okei_id = isr.okei_id   
			LEFT JOIN	Warehouse.SHKRawMaterialState sms   
			INNER JOIN	Warehouse.SHKRawMaterialStateDict smsd
				ON	smsd.state_id = sms.state_id
				ON	sms.shkrm_id = isr.shkrm_id   
			LEFT JOIN	Warehouse.SHKRawMaterialOnPlace smop   
			INNER JOIN	Warehouse.StoragePlace sp   
			INNER JOIN	Warehouse.ZoneOfResponse zor   
			INNER JOIN	Settings.OfficeSetting os
				ON	os.office_id = zor.office_id
				ON	zor.zor_id = sp.zor_id
				ON	sp.place_id = smop.place_id
				ON	smop.shkrm_id = isr.shkrm_id   
			INNER JOIN	Warehouse.SHKRawMaterialAmount sma
				ON	sma.shkrm_id = isr.shkrm_id
	WHERE	isr.inventory_id = @inventory_id
	
	SELECT	ie.employee_id,
			es.employee_name
	FROM	Warehouse.InventoryEmployee ie   
			INNER JOIN	Settings.EmployeeSetting es
				ON	es.employee_id = ie.employee_id
	WHERE	ie.inventory_id = @inventory_id
	
	SELECT	isp.place_id,
			sp.place_name,
			os.office_name
	FROM	Warehouse.InventoryStoragePlace isp   
			INNER JOIN	Warehouse.StoragePlace sp
				ON	sp.place_id = isp.place_id   
			INNER JOIN	Warehouse.ZoneOfResponse zor   
			INNER JOIN	Settings.OfficeSetting os
				ON	os.office_id = zor.office_id
				ON	zor.zor_id = sp.zor_id
	WHERE	isp.inventory_id = @inventory_id

	