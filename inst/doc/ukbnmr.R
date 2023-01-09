## ---- include = FALSE---------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ----eval=FALSE---------------------------------------------------------------
#  library(ukbnmr)
#  
#  decoded <- fread("path/to/decoded_ukbiobank_data.csv") # file save by ukbconv tool
#  
#  nmr <- extract_biomarkers(decoded)
#  biomarker_qc_flags <- extract_biomarker_qc_flags(decoded)
#  sample_qc_flags <- extract_sample_qc_flags(decoded)
#  
#  fwrite(nmr, file="path/to/nmr_biomarker_data.csv")
#  fwrite(biomarker_qc_flags, file="path/to/nmr_biomarker_qc_flags.csv")
#  fwrite(sample_qc_flags, file="path/to/nmr_sample_qc_flags.csv")

## -----------------------------------------------------------------------------
library(ukbnmr)

decoded <- ukbnmr::test_data # see help("test_data") for more details

nmr <- extract_biomarkers(decoded)
biomarker_qc_flags <- extract_biomarker_qc_flags(decoded)
sample_qc_flags <- extract_sample_qc_flags(decoded)

## ----eval=FALSE---------------------------------------------------------------
#  library(ukbnmr)
#  decoded <- fread("path/to/decoded_ukbiobank_data.csv") # file save by ukbconv tool
#  
#  processed <- remove_technical_variation(decoded)
#  
#  fwrite(processed$biomarkers, file="path/to/nmr_biomarker_data.csv")
#  fwrite(processed$biomarker_qc_flags, file="path/to/nmr_biomarker_qc_flags.csv")
#  fwrite(processed$sample_processing, file="path/to/nmr_sample_qc_flags.csv")
#  fwrite(processed$log_offset, file="path/to/nmr_biomarker_log_offset.csv")
#  fwrite(processed$outlier_plate_detection, file="path/to/outlier_plate_info.csv")

## -----------------------------------------------------------------------------
library(ukbnmr)

decoded <- ukbnmr::test_data # see help("test_data") for more details

processed <- remove_technical_variation(decoded)

## ----eval=FALSE---------------------------------------------------------------
#  library(ukbnmr)
#  
#  # First, if we haven't corrected for unwanted technical variation we do so
#  # using the appropriate function (see help("remove_technical_variation")).
#  decoded <- fread("path/to/decoded_ukbiobank_data.csv") # file save by ukbconv tool
#  
#  processed <- remove_technical_variation(decoded)
#  tech_qc <- processed$biomarkers
#  
#  fwrite(tech_qc, file="path/to/nmr_biomarker_data.csv")
#  fwrite(processed$biomarker_qc_flags, file="path/to/nmr_biomarker_qc_flags.csv")
#  fwrite(processed$sample_processing, file="path/to/nmr_sample_qc_flags.csv")
#  fwrite(processed$log_offset, file="path/to/nmr_biomarker_log_offset.csv")
#  fwrite(processed$outlier_plate_detection, file="path/to/outlier_plate_info.csv")
#  
#  # Otherwise assuming we load 'tech_qc' from "path/to/mr_biomarker_data.csv".
#  
#  # We now run code to adjust biomarkers for biological covariates. This code is
#  # not supplied by this package, but for illustrative purposes we assume the user
#  # has written a function to do this:
#  bio_qc <- user_function_to_adjust_biomarkers_for_covariates(tech_qc)
#  
#  # Now we recompute the composite biomarkers and derived ratios after
#  # adjustment for additional biological covariates
#  bio_qc <- recompute_derived_biomarkers(bio_qc)
#  fwrite(bio_qc, file="path/to/nmr_biomarkers_adjusted_for_covariates.csv")
#  
#  # You may also want to aggregate and save the quality control flags for each
#  # sample from the biomarkers underlying each derived biomarker or ratio,
#  # adding them as additional columns to the input data (see
#  # help("recompute_derived_biomarker_qc_flags")).
#  biomarker_qc_flags <- recompute_derived_biomarker_qc_flags(nmr)
#  fwrite(biomarker_qc_flags, file="path/to/biomarker_qc_flags.csv")

