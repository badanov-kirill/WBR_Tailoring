CREATE TABLE [Products].[Sketch] (
    [sketch_id]                           INT            IDENTITY (1, 1) NOT NULL,
    [is_deleted]                          BIT            NOT NULL,
    [st_id]                               INT            NOT NULL,
    [ss_id]                               INT            NOT NULL,
    [pic_count]                           TINYINT        NOT NULL,
    [tech_design]                         BIT            NOT NULL,
    [kind_id]                             INT            NULL,
    [subject_id]                          INT            NOT NULL,
    [descr]                               VARCHAR (1000) NULL,
    [create_employee_id]                  INT            NOT NULL,
    [create_dt]                           DATETIME2 (0)  NOT NULL,
    [employee_id]                         INT            NOT NULL,
    [dt]                                  DATETIME2 (0)  NOT NULL,
    [rv]                                  ROWVERSION     NOT NULL,
    [status_comment]                      VARCHAR (250)  NULL,
    [qp_id]                               TINYINT        NULL,
    [model_year]                          SMALLINT       NULL,
    [model_number]                        INT            NULL,
    [brand_id]                            INT            NULL,
    [season_id]                           INT            NULL,
    [style_id]                            INT            NULL,
    [wb_size_group_id]                    INT            NULL,
    [art_name_id]                         INT            NOT NULL,
    [constructor_employee_id]             INT            NULL,
    [pattern_name]                        VARCHAR (15)   NULL,
    [sa_local]                            VARCHAR (15)   NOT NULL,
    [sa]                                  VARCHAR (15)   NOT NULL,
    [ct_id]                               INT            NULL,
    [direction_id]                        INT            NULL,
    [imt_name]                            VARCHAR (100)  NULL,
    [base_sketch_id]                      INT            NULL,
    [pt_id]                               TINYINT        NULL,
    [pattern_print_dt]                    DATETIME2 (0)  NULL,
    [specification_dt]                    DATETIME2 (0)  NULL,
    [specification_employee_id]           INT            NULL,
    [technology_dt]                       DATETIME2 (0)  NULL,
    [constructor_coeffecient]             DECIMAL (2, 2) NULL,
    [constructor_coeffecient_employee_id] INT            NULL,
    [season_model_year]                   SMALLINT       NULL,
    [season_local_id]                     INT            NULL,
    [in_constructor_dt]                   DATETIME2 (0)  NULL,
    [construction_close_dt]               DATETIME2 (0)  NULL,
    [plan_site_dt]                        DATE           NULL,
    [technology_employee_id]              INT            NULL,
    [layout_dt]                           DATETIME2 (0)  NULL,
    [is_china_sample]                     BIT            NULL,
    [allow_purchase_no_close]             BIT            NULL,
    [pre_time_tech_seq]                   INT            NULL,
    [loops]                               TINYINT        NULL,
    [buttons]                             TINYINT        NULL,
    [days_for_purchase]                   SMALLINT       NULL,
    [sls_id]                              TINYINT        NULL,
    [fist_package_dt]                     DATETIME2 (0)  NULL,
    [kw_id]                               INT            NULL,
    CONSTRAINT [PK_Sketch] PRIMARY KEY CLUSTERED ([sketch_id] ASC),
    CONSTRAINT [FK_Sketch_art_name_id] FOREIGN KEY ([art_name_id]) REFERENCES [Products].[ArtName] ([art_name_id]),
    CONSTRAINT [FK_Sketch_base_sketch_id] FOREIGN KEY ([base_sketch_id]) REFERENCES [Products].[Sketch] ([sketch_id]),
    CONSTRAINT [FK_Sketch_brand_id] FOREIGN KEY ([brand_id]) REFERENCES [Products].[Brand] ([brand_id]),
    CONSTRAINT [FK_Sketch_ct_id] FOREIGN KEY ([ct_id]) REFERENCES [Material].[ClothType] ([ct_id]),
    CONSTRAINT [FK_Sketch_direction_id] FOREIGN KEY ([direction_id]) REFERENCES [Products].[Direction] ([direction_id]),
    CONSTRAINT [FK_Sketch_kind_id] FOREIGN KEY ([kind_id]) REFERENCES [Products].[Kind] ([kind_id]),
    CONSTRAINT [FK_Sketch_pt_id] FOREIGN KEY ([pt_id]) REFERENCES [Products].[ProductType] ([pt_id]),
    CONSTRAINT [FK_Sketch_qp_id] FOREIGN KEY ([qp_id]) REFERENCES [Products].[QueuePriority] ([qp_id]),
    CONSTRAINT [FK_Sketch_season_id] FOREIGN KEY ([season_id]) REFERENCES [Products].[Season] ([season_id]),
    CONSTRAINT [FK_Sketch_season_local_id] FOREIGN KEY ([season_local_id]) REFERENCES [Products].[SeasonLocal] ([season_local_id]),
    CONSTRAINT [FK_Sketch_sls_id] FOREIGN KEY ([sls_id]) REFERENCES [Products].[SketchLogicStatusDict] ([sls_id]),
    CONSTRAINT [FK_Sketch_ss_id] FOREIGN KEY ([ss_id]) REFERENCES [Products].[SketchStatus] ([ss_id]),
    CONSTRAINT [FK_Sketch_st_id] FOREIGN KEY ([st_id]) REFERENCES [Products].[SketchType] ([st_id]),
    CONSTRAINT [FK_Sketch_style_id] FOREIGN KEY ([style_id]) REFERENCES [Products].[Style] ([style_id]),
    CONSTRAINT [FK_Sketch_subject_id] FOREIGN KEY ([subject_id]) REFERENCES [Products].[Subject] ([subject_id]),
    CONSTRAINT [FK_Sketch_wb_size_group_id] FOREIGN KEY ([wb_size_group_id]) REFERENCES [Products].[WbSizeGroup] ([wb_size_group_id]),
    CONSTRAINT [FK_Sketch_kw_id] FOREIGN KEY (kw_id) REFERENCES [Products].[KeyWords] ([kw_id])
);



GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_Sketch_brand_id_st_id_model_year_season_id_model_number] ON Products.Sketch(brand_id, st_id, model_year, season_id, model_number) 
WHERE is_deleted = 0
ON [Indexes];

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_Sketch_art_name_id] ON Products.Sketch(art_name_id) WHERE is_deleted = 0 ON [Indexes]

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_Sketch_sa] ON Products.Sketch(sa) ON [Indexes]
GO
GRANT SELECT
    ON OBJECT::[Products].[Sketch] TO [wildberries\olap-orr]
    AS [dbo];

