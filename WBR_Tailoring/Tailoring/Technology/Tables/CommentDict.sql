CREATE TABLE [Technology].[CommentDict]
(
	comment_id     INT IDENTITY(1, 1) CONSTRAINT [PK_CommentDict] PRIMARY KEY CLUSTERED NOT NULL,
	comment        VARCHAR(100) NOT NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_Technology_CommentDict_comment] ON Technology.CommentDict(comment) ON [Indexes]