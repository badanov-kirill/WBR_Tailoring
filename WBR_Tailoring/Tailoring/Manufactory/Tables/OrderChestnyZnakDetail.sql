CREATE TABLE [Manufactory].[OrderChestnyZnakDetail]
(
	oczd_id          INT IDENTITY(1, 1) CONSTRAINT [PK_OrderChestnyZnakDetail] PRIMARY KEY CLUSTERED NOT NULL,
	ocz_id           INT CONSTRAINT [FK_OrderChestnyZnakDetail_ocz_id] FOREIGN KEY REFERENCES Manufactory.OrderChestnyZnak(ocz_id) NOT NULL,
	spcvts_id        INT CONSTRAINT [FK_OrderChestnyZnakDetail_spcvts_id] FOREIGN KEY REFERENCES Planing.SketchPlanColorVariantTS(spcvts_id) NOT NULL,
	ean              VARCHAR(13) NOT NULL,
	cnt              SMALLINT NOT NULL,
	load_item_dt     DATETIME2(0) NULL
)

GO
CREATE INDEX [IX_OrderChestnyZnakDetail_spcvts_id] ON Manufactory.OrderChestnyZnakDetail(spcvts_id) INCLUDE(oczd_id) ON [Indexes]
