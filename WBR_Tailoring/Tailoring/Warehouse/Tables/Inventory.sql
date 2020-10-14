CREATE TABLE [Warehouse].[Inventory]
(
	inventory_id INT IDENTITY(1,1) CONSTRAINT [PK_Inventory] PRIMARY KEY CLUSTERED NOT NULL,
	plan_start_dt DATE NOT NULL,
	plan_finish_dt DATE NOT NULL,
	create_dt DATETIME2(0) NOT NULL,
	create_employee_id INT NOT NULL,
	it_id TINYINT CONSTRAINT [FK_Inventory_it_id] FOREIGN KEY REFERENCES Warehouse.InventoryType(it_id) NOT NULL,
	comment VARCHAR(300) NULL,
	rmt_id                         INT CONSTRAINT [FK_Inventory_rmt_id] FOREIGN KEY REFERENCES Material.RawMaterialType(rmt_id) NULL,
	close_dt DATETIME2(0) NULL,
	close_employee_id INT NULL,
	lost_sum DECIMAL(15,2) NULL,
	is_deleted BIT NOT NULL,
	dt DATETIME2(0) NOT NULL,
	employee_id INT NOT NULL
)
