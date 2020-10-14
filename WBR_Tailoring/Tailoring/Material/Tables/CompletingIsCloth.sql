CREATE TABLE [Material].[CompletingIsCloth]
(
	completing_id INT CONSTRAINT [FK_CompletingIsCloth_completing_id] FOREIGN KEY REFERENCES Material.Completing(completing_id) NOT NULL,
	CONSTRAINT [PK_CompletingIsCloth] PRIMARY KEY CLUSTERED(completing_id)
)
