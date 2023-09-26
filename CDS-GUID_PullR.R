#!/usr/bin/env Rscript

#Cancer Data Services - GUID_PullR.R

#This script will take a CDS metadata manifest file and pull each file's respective GUID from indexd and place the in the manifest.

##################
#
# USAGE
#
##################

#Run the following command in a terminal where R is installed for help.

#Rscript --vanilla CDS-GUID_PulleR.R --help


##################
#
# Env. Setup
#
##################

#List of needed packages
list_of_packages=c("readr","readxl","openxlsx","stringi","dplyr","tidyr","janitor","curl","optparse","tools")

#Based on the packages that are present, install ones that are required.
new.packages <- list_of_packages[!(list_of_packages %in% installed.packages()[,"Package"])]
suppressMessages(if(length(new.packages)) install.packages(new.packages, repos = "http://cran.us.r-project.org"))

#Load libraries.
suppressMessages(library(readr,verbose = F))
suppressMessages(library(readxl, verbose = F))
suppressMessages(library(openxlsx, verbose = F))
suppressMessages(library(dplyr, verbose = F))
suppressMessages(library(tidyr, verbose = F))
suppressMessages(library(stringi,verbose = F))
suppressMessages(library(janitor,verbose = F))
suppressMessages(library(curl,verbose = F))
suppressMessages(library(optparse,verbose = F))
suppressMessages(library(tools,verbose = F))


#remove objects that are no longer used.
rm(list_of_packages)
rm(new.packages)


##################
#
# Arg parse
#
##################

#Option list for arg parse
option_list = list(
  make_option(c("-f", "--file"), type="character", default=NULL, 
              help="dataset file (.xlsx, .tsv, .csv)", metavar="character")
)

#create list of options and values for file input
opt_parser = OptionParser(option_list=option_list, description = "\nCDS-GUID_PullR v2.0.0")
opt = parse_args(opt_parser)

#If no options are presented, return --help, stop and print the following message.
if (is.null(opt$file)){
  print_help(opt_parser)
  cat("Please supply the input file (-f).\n\n")
  suppressMessages(stop(call.=FALSE))
}


#Data file pathway
file_path=file_path_as_absolute(opt$file)


###########
#
# File name rework
#
###########

#Rework the file path to obtain a file extension.
file_name=stri_reverse(stri_split_fixed(stri_reverse(basename(file_path)),pattern = ".", n=2)[[1]][2])
ext=tolower(stri_reverse(stri_split_fixed(stri_reverse(basename(file_path)),pattern = ".", n=2)[[1]][1]))
path=paste(dirname(file_path),"/",sep = "")

#Output file name based on input file name and date/time stamped.
output_file=paste(file_name,
                  "_wGUID",
                  stri_replace_all_fixed(
                    str = Sys.Date(),
                    pattern = "-",
                    replacement = ""),
                  sep="")


NA_bank=c("NA","na","N/A","n/a","")

#Read in file with trim_ws=TRUE
if (ext == "tsv"){
  df=suppressMessages(read_tsv(file = file_path, trim_ws = TRUE, na=NA_bank, guess_max = 1000000, col_types = cols(.default = col_character())))
}else if (ext == "csv"){
  df=suppressMessages(read_csv(file = file_path, trim_ws = TRUE, na=NA_bank, guess_max = 1000000, col_types = cols(.default = col_character())))
}else if (ext == "xlsx"){
  df=suppressMessages(read_xlsx(path = file_path, trim_ws = TRUE, na=NA_bank, sheet = "Metadata", guess_max = 1000000, col_types = "text"))
}else{
  stop("\n\nERROR: Please submit a data file that is in either xlsx, tsv or csv format.\n\n")
}

#A start message for the user that the validation is underway.
cat("Indexd is being queried at this time.\n")

#############
#
# Data frame manipulation
#
#############
df=df%>%
  mutate(guid=NA)%>%
  select(guid, everything())

pb=txtProgressBar(min=0,max=dim(df)[1],style = 3)

for (x in 1:dim(df)[1]){
  setTxtProgressBar(pb,x)
  
  file_size=df$file_size[x]
  file_md5sum=df$md5sum[x]
  
  contents=suppressWarnings(readLines(curl(url = paste("https://nci-crdc.datacommons.io/index/index?size=",file_size,"&hash=md5:",file_md5sum,sep = "")), warn = F))
  
  #Close readLines function after saving output to variable, this will avoid warnings later.
  on.exit(close(contents))
  #insert sleep to prevent spamming the API
  Sys.sleep(0.25)

  contents=stri_split_fixed(str = contents, pattern = '\"did\":\"', n = 2)[[1]][2]
  guid=stri_split_fixed(str = contents, pattern = '\",\"file_name\"', n = 2)[[1]][1]
  
  df$guid[x]=guid
}

###############
#
# Write out
#
###############

#Write out file
if (ext == "tsv"){
  suppressMessages(write_tsv(df, file = paste(path,output_file,".tsv",sep = ""), na=""))
}else if (ext == "csv"){
  suppressMessages(write_csv(df, file = paste(path,output_file,".csv",sep = ""), na=""))
}else if (ext == "xlsx"){
  wb=openxlsx::loadWorkbook(file = file_path)
  openxlsx::deleteData(wb, sheet = "Metadata",rows = 1:(dim(df)[1]+1),cols=1:(dim(df)[2]+1),gridExpand = TRUE)
  openxlsx::writeData(wb=wb, sheet="Metadata", df)
  openxlsx::saveWorkbook(wb = wb,file = paste(path,output_file,".xlsx",sep = ""), overwrite = T)
}


cat(paste("\n\nProcess Complete.\n\nThe output file can be found here: ",path,"\n\n",sep = "")) 
