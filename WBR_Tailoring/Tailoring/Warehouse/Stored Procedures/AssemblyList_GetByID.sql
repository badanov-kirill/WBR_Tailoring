CREATE PROCEDURE [Warehouse].[AssemblyList_GetByID]
	@al_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	al.al_id,
			CAST(al.create_dt AS DATETIME) create_dt,
			al.create_employee_id,
			al.workshop_id,
			CAST(al.shipping_dt AS DATETIME) shipping_dt,
			CAST(al.close_dt AS DATETIME) close_dt,
			al.close_employee_id,
			CAST(CAST(al.rv AS BIGINT) AS VARCHAR(19)) rv_bigint
	FROM	Warehouse.AssemblyList al
	WHERE	al.al_id = @al_id
	
	SELECT	ald.shkrm_id,
			rmt.rmt_name,
			a.art_name,
			cc.color_name,
			sp.place_name,
			zor.zor_name,
			ald.comment
	FROM	Warehouse.AssemblyListDetail ald   
			LEFT JOIN	Warehouse.SHKRawMaterialActualInfo smai   
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = smai.rmt_id   
			INNER JOIN	Material.ClothColor cc
				ON	cc.color_id = smai.color_id   
			INNER JOIN	Material.Article a
				ON	a.art_id = smai.art_id
				ON	smai.shkrm_id = ald.shkrm_id   
			LEFT JOIN	Warehouse.SHKRawMaterialOnPlace smop   
			INNER JOIN	Warehouse.StoragePlace sp
				ON	sp.place_id = smop.place_id   
			INNER JOIN	Warehouse.ZoneOfResponse zor
				ON	zor.zor_id = sp.zor_id
				ON	smop.shkrm_id = ald.shkrm_id
	WHERE	ald.al_id = @al_id
