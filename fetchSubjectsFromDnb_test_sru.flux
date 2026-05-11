default version="test/";
default sruHarvest=FLUX_DIR + version +"sru_records.xml";
default outfile=FLUX_DIR + version + "dnbSubjects.xml";
default lobidHarvest = FLUX_DIR + version + "dnbSubjects.jsonl";
default lookupFile = FLUX_DIR + version + "almaMmsId2dnbId.tsv";

// Outcomment to not harvest the data every time.

// "Start harvesting lobid."
// | print;
// 
// "https://lobid.org/resources/search?q=_exists_%3AdnbId+AND+NOT+subject.type%3A%22ComplexSubject%22+AND+inCollection.id%3A%22http%3A%2F%2Flobid.org%2Forganisations%2FDE-655%23%21%22+AND+NOT+_exists_%3AzdbId+AND+Gem%C3%BCse"
// | open-http(header="User-Agent: hbz/dnb-subject-harvester", accept="application/x-jsonlines")
// | as-lines
// | write(lobidHarvest)
// ;

"Harvesting lobid finished. Start creating dnbId2zdbId map."
| print;

lobidHarvest
| open-file
| as-lines
| decode-json
| fix("retain('almaMmsId','dnbId')")
| encode-csv(noQuotes="true", separator="\t")
| write(lookupFile)
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
| fix(FLUX_DIR + "subject.fix",*)
| batch-log(batchSize="10")
| encode-marcxml
| write(outfile)
;

"Create a list of broken dnbIds."
| print;

//sruHarvest
//| open-file
//| as-lines
//| filter-strings("<records/>",passmatches="true")
//| match(pattern=".*dnb.idn=(.+)</query>.+$",replacement="$1")
//| decode-csv(separator="\t")
//| fix(FLUX_DIR + "failed.fix",*)
//| batch-log(batchSize="10")
//| encode-csv(separator="\t",includeheader="true",noQuotes="true")
//| write(FLUX_DIR + "test/failed.tsv")
//;