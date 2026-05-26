//"https://lobid.org/resources/search?q=_exists_%3AdnbId+AND+NOT+subject.type%3A%22ComplexSubject%22+AND+inCollection.id%3A%22http%3A%2F%2Flobid.org%2Forganisations%2FDE-655%23%21%22+AND+NOT+_exists_%3AzdbId&format=jsonl"
//| open-http(header="User-Agent: hbz/dnb-subject-harvester")
//| as-lines
//| write(FLUX_DIR + "prod/dnbSubjects.jsonl")
//;

FLUX_DIR + "prod/dnbSubjects.jsonl"
| open-file
| as-lines
| decode-json
| fix("retain('dnbId')")
| literal-to-object
| template("https://d-nb.info/${o}/about/marcxml")
| catch-object-exception
| open-http(header="User-Agent: hbz/dnbSubjectHarvester", accept="application/xml")
| decode-xml
| handle-marcxml
| batch-log
| fix(FLUX_DIR + "subject.fix")
//| batch-log
| encode-marcxml
| write(FLUX_DIR + "prod/dnbSubjects.xml")
;