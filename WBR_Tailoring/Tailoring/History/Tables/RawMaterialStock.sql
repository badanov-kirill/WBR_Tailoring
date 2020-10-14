CREATE TABLE [History].[RawMaterialStock]
(
	hrms_id                INT IDENTITY(1, 1) CONSTRAINT [PK_History_RawMaterialStock] PRIMARY KEY CLUSTERED NOT NULL,
	rms_id                 INT NOT NULL,
	supplier_id            INT NOT NULL,
	rmt_id                 INT NOT NULL,
	color_id               INT NULL,
	frame_width            SMALLINT NULL,
	okei_id                INT NOT NULL,
	qty                    DECIMAL(15, 3) NOT NULL,
	price_cur              DECIMAL(15, 2) NOT NULL,
	currency_id            INT NOT NULL,
	nds                    TINYINT NOT NULL,
	dt                     dbo.SECONDSTIME NOT NULL,
	employee_id            INT NOT NULL,
	days_delivery_time     TINYINT NOT NULL,
	end_dt_offer           dbo.SECONDSTIME NOT NULL,
	comment                VARCHAR(300) NULL
)
