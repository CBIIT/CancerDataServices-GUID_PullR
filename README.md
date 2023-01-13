# CancerDataServices-GUID_PullR
This script will take an already indexed CDS metadata manifest file and pull each file's respective GUID from indexd and place the in the manifest.

To run the script on a CDS template, run the following command in a terminal where R is installed for help.

```
Rscript --vanilla CDS-GUID_PullR.R -h
```

```
Usage: CDS-GUID_PullR.R [options]

CDS-GUID_PullR v2.0.0

Options:
	-f CHARACTER, --file=CHARACTER
		dataset file (.xlsx, .tsv, .csv)

	-h, --help
		Show this help message and exit
```

To run this script on an example file, please use the following:

```
Rscript --vanilla CDS-GUID_PullR.R -f test_files/a_all_pass-v1.3.1.xlsx
Indexd is being queried at this time.
  |======================================================================| 100%


Process Complete.

The output file can be found here: CancerDataServices-GUID_PullR/test_files/
```

NOTE: Warning messages may appear during the running of this script, these are expected as many calls are being made to the indexd endpoint to pull GUID information.
