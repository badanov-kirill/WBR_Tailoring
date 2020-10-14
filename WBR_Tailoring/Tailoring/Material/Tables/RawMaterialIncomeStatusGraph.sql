CREATE TABLE [Material].[RawMaterialIncomeStatusGraph]
(
	rmis_src_id     INT CONSTRAINT [FK_RawMaterialIncomeStatusGraph_rmis_src_id] FOREIGN KEY REFERENCES Material.RawMaterialIncomeStatus(rmis_id) NOT NULL,
	rmis_dst_id     INT CONSTRAINT [FK_RawMaterialIncomeStatusGraph_rmis_dst_id] FOREIGN KEY REFERENCES Material.RawMaterialIncomeStatus(rmis_id) NOT NULL,
	CONSTRAINT [PK_RawMaterialIncomeStatusGraph] PRIMARY KEY CLUSTERED(rmis_src_id, rmis_dst_id)
)
