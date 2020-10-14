CREATE TABLE [Suppliers].[RawMaterialStock]
(
	rms_id                 INT IDENTITY(1, 1) CONSTRAINT [PK_RawMaterialStock] PRIMARY KEY CLUSTERED NOT NULL,
	supplier_id            INT CONSTRAINT [FK_RawMaterialStock_supplier_id] FOREIGN KEY REFERENCES Suppliers.Supplier(supplier_id) NOT NULL,
	rmt_id                 INT CONSTRAINT [FK_RawMaterialStock_rmt_id] FOREIGN KEY REFERENCES Material.RawMaterialType(rmt_id) NOT NULL,
	color_id               INT CONSTRAINT [FK_RawMaterialStock_color_id] FOREIGN KEY REFERENCES Material.ClothColor(color_id) NOT NULL,
	frame_width            SMALLINT NULL,
	okei_id                INT CONSTRAINT [FK_RawMaterialStock_okei_id] FOREIGN KEY REFERENCES Qualifiers.OKEI(okei_id) NOT NULL,
	qty                    DECIMAL(15, 3) NOT NULL,
	price_cur              DECIMAL(15, 2) NOT NULL,
	currency_id            INT CONSTRAINT [FK_RawMaterialStock_currency_id] FOREIGN KEY REFERENCES RefBook.Currency(currency_id) NOT NULL,
	nds                    TINYINT CONSTRAINT [FK_RawMaterialStock_nds] FOREIGN KEY REFERENCES RefBook.NDS(nds) NOT NULL,
	dt                     dbo.SECONDSTIME NOT NULL,
	employee_id            INT NOT NULL,
	days_delivery_time     TINYINT NOT NULL,
	end_dt_offer           dbo.SECONDSTIME NOT NULL,
	comment                VARCHAR(300) NULL
)
