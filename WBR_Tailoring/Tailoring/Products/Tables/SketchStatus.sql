CREATE TABLE [Products].[SketchStatus] (
    [ss_id]         INT          IDENTITY (1, 1) NOT NULL,
    [ss_name]       VARCHAR (50) NOT NULL,
    [ss_short_name] VARCHAR (50) NULL,
    CONSTRAINT [PK_SketchStatus] PRIMARY KEY CLUSTERED ([ss_id] ASC)
);



GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_SketchStatus_ss_name] ON Products.SketchStatus(ss_name) ON [Indexes]
GO
GRANT SELECT
    ON OBJECT::[Products].[SketchStatus] TO [wildberries\olap-orr]
    AS [dbo];

