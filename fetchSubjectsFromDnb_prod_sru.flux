default sruHarvest="prod/sru_records.xml";
default outfile=FLUX_DIR + "prod/dnbSubjects.xml.gz";
default lobidHarvest = "test/dnbSubjects.jsonl";
default version="prod/";


"Start harvesting lobid."
| print;

"https://lobid.org/resources/search?q=_exists_%3AdnbId+AND+NOT+subject.type%3A%22ComplexSubject%22+AND+inCollection.id%3A%22http%3A%2F%2Flobid.org%2Forganisations%2FDE-655%23%21%22+AND+NOT+_exists_%3AzdbId&format=jsonl"
| open-http(header="User-Agent: hbz/dnb-subject-harvester")
| as-lines
| write(lobidHarvest)
;

"Harvesting lobid finished. Start creating dnbId2zdbId map."
| print;

FLUX_DIR + "prod/dnbSubjects.jsonl"
| open-file
| as-lines
| decode-json
| fix("retain('almaMmsId','dnbId')")
| encode-csv(noQuotes="true", separator="\t")
| write("prod/almaMmsId2dnbId.tsv")
;

"Map finished. Start harvesting sru."
| print;

lobidHarvest
| open-file
| as-lines
| decode-json
| fix("retain('dnbId')")
| literal-to-object
| template("https://services.dnb.de/sru/dnb?version=1.1&operation=searchRetrieve&query=dnb.idn=${o}&recordSchema=MARC21-xml")
| catch-object-exception
| open-http(header="User-Agent: hbz/dnbSubjectHarvester", accept="application/xml")
| as-records
// The following two steps create a single xml file from the multiple incoming sru requests, saved into a harvest tag
| match(pattern="<\\?xml version=.*?>", replacement="")
| object-batch-log(batchSize="100")
| write(sruHarvest, header="<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<harvest>", footer="</harvest>")
;


"SRU Harvest finished. Start harvesting dnb subject data."
| print;

sruHarvest
| open-file
| decode-xml
| handle-marcxml
| batch-log
| fix(FLUX_DIR + "subject.fix",*)
//| batch-log
| encode-marcxml
| object-batch-log 
| write(outfile, compression="gzip") // compression is better for big file
;
