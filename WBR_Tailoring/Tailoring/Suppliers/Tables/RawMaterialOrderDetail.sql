CREATE TABLE [Suppliers].[RawMaterialOrderDetail]
(
	rmod_id         INT IDENTITY(1, 1) CONSTRAINT [PK_RawMaterialOrderDetail] PRIMARY KEY CLUSTERED NOT NULL,
	rmo_id          INT CONSTRAINT [FK_RawMaterialOrderDetail_rmo_id] FOREIGN KEY REFERENCES Suppliers.RawMaterialOrder(rmo_id) NOT NULL,
	rmt_id          INT CONSTRAINT [FK_RawMaterialOrderDetail_rmt_id] FOREIGN KEY REFERENCES Material.RawMaterialType(rmt_id) NOT NULL,
	color_id        INT CONSTRAINT [FK_RawMaterialOrderDetail_color_id] FOREIGN KEY REFERENCES Material.ClothColor(color_id) NOT NULL,
	okei_id         INT CONSTRAINT [FK_RawMaterialOrderDetail_okei_id] FOREIGN KEY REFERENCES Qualifiers.OKEI(okei_id) NOT NULL,
	frame_width     SMALLINT NULL,
	comment         VARCHAR(300) NULL,
	qty             DECIMAL(9, 3) NOT NULL,
	price_cur       DECIMAL(9, 2) NOT NULL,
	currency_id     INT CONSTRAINT [FK_RawMaterialOrderDetail_currency_id] FOREIGN KEY REFERENCES RefBook.Currency(currency_id) NOT NULL,
	rmods_id        TINYINT CONSTRAINT [FK_RawMaterialOrderDetail] FOREIGN KEY REFERENCES Suppliers.RawMaterialOrderDetailStatus(rmods_id) NOT NULL,
	employee_id     INT NOT NULL,
	dt              DATETIME2(0) NOT NULL
)
