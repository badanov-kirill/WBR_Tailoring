CREATE TABLE [Products].[SubjectGroupType]
(
	group_id                   INT CONSTRAINT [PK_SubjectGroupType] PRIMARY KEY CLUSTERED NOT NULL,
	group_name                 VARCHAR(29) NOT NULL,
	is_kind_required           BIT NOT NULL,
	is_collection_required     BIT NOT NULL,
	is_season_required         BIT NOT NULL,
	is_style_required          BIT NOT NULL,
	is_direction_required      BIT NOT NULL
)
