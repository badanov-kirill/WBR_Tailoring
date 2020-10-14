CREATE TABLE [Planing].[CoveringIssueSHKRm] (
    [cisr_id]                       INT            IDENTITY (1, 1) NOT NULL,
    [covering_id]                   INT            NOT NULL,
    [shkrm_id]                      INT            NOT NULL,
    [okei_id]                       INT            NOT NULL,
    [qty]                           DECIMAL (9, 3) NOT NULL,
    [stor_unit_residues_okei_id]    INT            NOT NULL,
    [stor_unit_residues_qty]        DECIMAL (9, 3) NOT NULL,
    [dt]                            DATETIME2 (0)  NOT NULL,
    [employee_id]                   INT            NOT NULL,
    [recive_employee_id]            INT            NOT NULL,
    [return_qty]                    DECIMAL (9, 3) NULL,
    [return_stor_unit_residues_qty] DECIMAL (9, 3) NULL,
    [return_dt]                     DATETIME2 (0)  NULL,
    [return_employee_id]            INT            NULL,
    [return_recive_employee_id]     INT            NULL,
    CONSTRAINT [PK_CoveringIssueSHKRm] PRIMARY KEY CLUSTERED ([cisr_id] ASC),
    CONSTRAINT [CH_CoveringIssueSHKRm_qty] CHECK ([qty]>(0)),
    CONSTRAINT [CH_CoveringIssueSHKRm_su_qty] CHECK ([stor_unit_residues_qty]>(0)),
    CONSTRAINT [FK_CoveringIssueSHKRm_covering_id] FOREIGN KEY ([covering_id]) REFERENCES [Planing].[Covering] ([covering_id]),
    CONSTRAINT [FK_CoveringIssueSHKRm_okei_id] FOREIGN KEY ([okei_id]) REFERENCES [Qualifiers].[OKEI] ([okei_id]),
    CONSTRAINT [FK_CoveringIssueSHKRm_shkrm_id] FOREIGN KEY ([shkrm_id]) REFERENCES [Warehouse].[SHKRawMaterial] ([shkrm_id]),
    CONSTRAINT [FK_CoveringIssueSHKRm_stor_unit_res_okei_id] FOREIGN KEY ([stor_unit_residues_okei_id]) REFERENCES [Qualifiers].[OKEI] ([okei_id])
);



GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_CoveringIssueSHKRm_shkrm_id] ON Planing.CoveringIssueSHKRm(shkrm_id) WHERE return_dt IS NULL ON [Indexes]

GO
CREATE NONCLUSTERED INDEX [IX_CoveringIssueSHKRm_shkrm_id] ON Planing.CoveringIssueSHKRm(shkrm_id) INCLUDE(covering_id, stor_unit_residues_qty, return_stor_unit_residues_qty) ON [Indexes]
GO
GRANT SELECT
    ON OBJECT::[Planing].[CoveringIssueSHKRm] TO [wildberries\olap-orr]
    AS [dbo];

