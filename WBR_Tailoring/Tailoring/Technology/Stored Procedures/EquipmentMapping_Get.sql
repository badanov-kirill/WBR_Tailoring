CREATE PROCEDURE [Technology].[EquipmentMapping_Get]
	@ct_id INT = NULL,
	@ta_id INT = NULL,
	@equipment_id INT = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	em.ct_id,
			em.ta_id,
			em.equipment_id,
			em.discharge_id,
			ct.ct_name,
			ta.ta_name,
			e.equipment_name
	FROM	Technology.EquipmentMapping em   
			INNER JOIN	Material.ClothType ct
				ON	ct.ct_id = em.ct_id   
			INNER JOIN	Technology.TechAction ta
				ON	ta.ta_id = em.ta_id   
			INNER JOIN	Technology.Equipment e
				ON	e.equipment_id = em.equipment_id
	WHERE	(@ct_id IS NULL OR em.ct_id = @ct_id)
			AND	(@ta_id IS NULL OR em.ta_id = @ta_id)
			AND	(@equipment_id IS NULL OR em.equipment_id = @equipment_id)
			AND e.is_deleted = 0
			AND ta.is_deleted = 0