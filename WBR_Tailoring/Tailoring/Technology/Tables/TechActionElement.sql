CREATE TABLE [Technology].[TechActionElement]
(
	ta_id          INT CONSTRAINT [FK_TechActionElement_action_id] FOREIGN KEY REFERENCES Technology.TechAction(ta_id) NOT NULL,
	element_id     INT CONSTRAINT [FK_TechActionElement_element_id] FOREIGN KEY REFERENCES Technology.Element(element_id) NOT NULL,
	CONSTRAINT [PK_TechActionElement] PRIMARY KEY CLUSTERED(ta_id, element_id)
)