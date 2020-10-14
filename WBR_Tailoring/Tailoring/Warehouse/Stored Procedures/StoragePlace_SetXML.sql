CREATE PROCEDURE [Warehouse].[StoragePlace_SetXML]
	@data_xml XML,
	@employee_id INT
AS
	SET NOCOUNT ON
	
	DECLARE @storageplaces Warehouse.StoragePlaces
	
	INSERT INTO @storageplaces
		(
			place_id,
			place_name,
			stage,
			street,
			section,
			rack,
			field,
			place_type_id,
			zor_id,
			is_deleted
		)
	SELECT	ml.value('@id', 'int')          place_id,
			ml.value('@name', 'varchar(50)') place_name,
			ml.value('@stage', 'int')       stage,
			ml.value('@street', 'int')      street,
			ml.value('@section', 'int')     section,
			ml.value('@rack', 'int')        rack,
			ml.value('@field', 'int')       field,
			ml.value('@type', 'int')        place_type_id,
			ml.value('@zone', 'int')        zor_id,
			ml.value('@del', 'bit')         is_deleted
	FROM	@data_xml.nodes('root/sp')x(ml)
	
	EXEC Warehouse.StoragePlace_Set
	     @storageplaces = @storageplaces,
	     @employee_id = @employee_id