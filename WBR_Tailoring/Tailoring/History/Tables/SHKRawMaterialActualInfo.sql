CREATE TABLE [History].[SHKRawMaterialActualInfo] (
    [log_id]                     INT             IDENTITY (1, 1) NOT NULL,
    [shkrm_id]                   INT             NOT NULL,
    [doc_id]                     INT             NULL,
    [doc_type_id]                TINYINT         NULL,
    [suppliercontract_id]        INT             NULL,
    [rmt_id]                     INT             NULL,
    [art_id]                     INT             NULL,
    [color_id]                   INT             NULL,
    [su_id]                      INT             NULL,
    [okei_id]                    INT             NULL,
    [qty]                        DECIMAL (9, 3)  NULL,
    [stor_unit_residues_okei_id] INT             NULL,
    [stor_unit_residues_qty]     DECIMAL (9, 3)  NULL,
    [amount]                     DECIMAL (19, 8) NULL,
    [dt]                         DATETIME2 (0)   NOT NULL,
    [employee_id]                INT             NOT NULL,
    [frame_width]                SMALLINT        NULL,
    [is_defected]                BIT             NULL,
    [is_deleted]                 BIT             NULL,
    [proc_id]                    INT             NOT NULL,
    [nds]                        TINYINT         NULL,
    [gross_mass]                 INT             NULL,
    [is_terminal_residues]       BIT             NULL,
    [tissue_density]             SMALLINT        NULL,
    [fabricator_id]              INT             NULL,
    CONSTRAINT [PK_History_SHKRawMaterialActualInfo] PRIMARY KEY CLUSTERED ([log_id] ASC)
);



GO
CREATE NONCLUSTERED INDEX [IX_History_SHKRawMaterialActualInfo_shkrm_id] ON History.SHKRawMaterialActualInfo(shkrm_id) ON [Indexes]