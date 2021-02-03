CREATE ROLE [ViewDefinition]
    AUTHORIZATION [dbo];





GO
ALTER ROLE [ViewDefinition] ADD MEMBER [WILDBERRIES\sqlreport];



GO
ALTER ROLE [ViewDefinition] ADD MEMBER [badanov];

