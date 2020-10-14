CREATE TABLE [Products].[RulesKinds]
(
	rule_id     INT NOT NULL,
	kind_id     INT CONSTRAINT [FK_RulesKinds_kind_id] FOREIGN KEY REFERENCES Products.Kind(kind_id) NOT NULL,
	CONSTRAINT [PK_RulesKinds] PRIMARY KEY CLUSTERED(rule_id, kind_id)
)
