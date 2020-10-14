CREATE TABLE [Logistics].[TransferBoxSpecialSPCV]
(
	transfer_box_id     BIGINT CONSTRAINT [FK_TransferBoxSpecialSPCV_transfer_box_id] FOREIGN KEY REFERENCES Logistics.TransferBoxSpecial(transfer_box_id) NOT NULL,
	spcv_id             INT CONSTRAINT [FK_TransferBoxSpecialSPCV_spcv_id] FOREIGN KEY REFERENCES Planing.SketchPlanColorVariant(spcv_id) NOT NULL,
	CONSTRAINT [PK_TransferBoxSpecialSPCV] PRIMARY KEY CLUSTERED(transfer_box_id, spcv_id)
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_TransferBoxSpecialSPCV_spcv_id] ON Logistics.TransferBoxSpecialSPCV(spcv_id, transfer_box_id) ON [Indexes]