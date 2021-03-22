CREATE TABLE [Products].[KeyWords]
(
	kw_id        INT IDENTITY(1, 1) CONSTRAINT [PK_KeyWords] PRIMARY KEY CLUSTERED NOT NULL,
	key_word     VARCHAR(400) NOT NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_KeyWords_key_word] ON Products.KeyWords(key_word) ON [Indexes]