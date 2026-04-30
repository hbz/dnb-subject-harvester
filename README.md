# dnbSubjectHarvester
Script that fetches the subjects 6XX from dnb records for NZ records that are missing subjects.

Currently the script searches for all records with dnbId, from the NZ and without zdbId and without complexSubjects in lobid-resources. Then checks DNB for the marcxml and creates reduced marcxml with only `001` and `689`.

To be determined if other subjects should be kept.
