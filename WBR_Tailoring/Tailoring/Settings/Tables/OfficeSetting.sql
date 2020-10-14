CREATE TABLE [Settings].[OfficeSetting]
(
	office_id                        INT CONSTRAINT [PK_OfficeSetting] PRIMARY KEY CLUSTERED NOT NULL,
	office_name                      VARCHAR(50) NOT NULL,
	buffer_zone_place_id             INT CONSTRAINT [FK_OfficeSetting_buffer_zone_place_id] FOREIGN KEY REFERENCES Warehouse.StoragePlace(place_id) NOT NULL,
	employee_id                      INT NOT NULL,
	dt                               dbo.SECONDSTIME NOT NULL,
	view_organization                VARCHAR(900) NOT NULL,
	office_address                   VARCHAR(500) NOT NULL,
	okpo_code                        VARCHAR(10) NOT NULL,
	accountant                       VARCHAR(50) NULL,
	authorized_shipping_position     VARCHAR(100) NULL,
	authorized_shipping_name         VARCHAR(100) NULL,
	made_shipping_position           VARCHAR(100) NULL,
	organization_name                VARCHAR(100) NULL,
	workshop_id                      INT CONSTRAINT [FK_OfficeSetting_workshop_id] FOREIGN KEY REFERENCES Warehouse.Workshop(workshop_id) NULL,
	design_workshop_id               INT CONSTRAINT [FK_OfficeSetting_design_workshop_id] FOREIGN KEY REFERENCES Warehouse.Workshop(workshop_id) NULL,
	is_main_wh                       BIT NOT NULL,
	cutting_tariff                   DECIMAL(9, 6) NOT NULL,
	cfo_id                           INT NOT NULL,
	label_address                    VARCHAR(500) NULL,
	buh_vas_uid						 VARCHAR(36) NOT NULL,
	glue_edge_tariff				 DECIMAL(9, 6) NOT NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_OfficeSetting_is_main_wh] ON Settings.OfficeSetting(is_main_wh) WHERE is_main_wh = 1 ON [Indexes]