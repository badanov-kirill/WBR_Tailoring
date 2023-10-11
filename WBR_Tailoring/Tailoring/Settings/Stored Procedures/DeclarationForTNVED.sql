CREATE PROCEDURE Settings.DeclarationForTNVED
@subject_id INT,
@ct_id INT,
@consist_type_id INT 

AS
select sd.declaration_id, sd.declaration_number + ' c: '+ cast(sd.end_date as char) +' по:' + cast(sd.end_date as char) as declarationFull
from  Products.TNVED_Settigs tnvds
	INNER JOIN Products.TNVED t
		ON	t.tnved_id = tnvds.tnved_id 
	INNER JOIN Settings.Declarations_TNVED dt
		ON dt.tnved_id = t.tnved_id
	INNER JOIN  Settings.Declarations sd
		ON sd.declaration_id = dt.declaration_id
	AND GETDATE() between sd.start_date and sd.end_date 
WHERE
tnvds.subject_id = @subject_id 
AND tnvds.ct_id = @ct_id
AND tnvds.consist_type_id = @consist_type_id