## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ----eval=FALSE---------------------------------------------------------------
# library(ukbnmr)
# library(data.table) # for fast reading and writing of csv files using fread() and fwrite()
# 
# # Load exported field data saved by the Table Exporter tool on the RAP
# exported <- fread("path/to/exported_ukbiobank_phenotype_data.csv")
# 
# nmr <- extract_biomarkers(exported)
# biomarker_qc_flags <- extract_biomarker_qc_flags(exported)
# sample_qc_flags <- extract_sample_qc_flags(exported)
# 
# fwrite(nmr, file="path/to/nmr_biomarker_data.csv")
# fwrite(biomarker_qc_flags, file="path/to/nmr_biomarker_qc_flags.csv")
# fwrite(sample_qc_flags, file="path/to/nmr_sample_qc_flags.csv")

## -----------------------------------------------------------------------------
library(ukbnmr)

exported <- ukbnmr::test_data # see help("test_data") for more details

nmr <- extract_biomarkers(exported)
biomarker_qc_flags <- extract_biomarker_qc_flags(exported)
sample_qc_flags <- extract_sample_qc_flags(exported)

## ----eval=FALSE---------------------------------------------------------------
# library(ukbnmr)
# library(data.table) # for fast reading and writing of csv files using fread() and fwrite()
# 
# # Load exported field data saved by the Table Exporter tool on the RAP
# exported <- fread("path/to/exported_ukbiobank_phenotype_data.csv")
# 
# processed <- remove_technical_variation(exported)
# 
# fwrite(processed$biomarkers, file="path/to/nmr_biomarker_data.csv")
# fwrite(processed$biomarker_qc_flags, file="path/to/nmr_biomarker_qc_flags.csv")
# fwrite(processed$sample_processing, file="path/to/nmr_sample_qc_flags.csv")
# fwrite(processed$log_offset, file="path/to/nmr_biomarker_log_offset.csv")
# fwrite(processed$outlier_plate_detection, file="path/to/outlier_plate_info.csv")

## -----------------------------------------------------------------------------
library(ukbnmr)

exported <- ukbnmr::test_data # see help("test_data") for more details

processed <- remove_technical_variation(exported)

## ----eval=FALSE---------------------------------------------------------------
# library(ukbnmr)
# library(data.table) # for fast reading and writing of csv files using fread() and fwrite()
# library(MASS) # Robust linear regression
# 
# # Load exported field data saved by the Table Exporter tool on the RAP
# exported <- fread("path/to/exported_ukbiobank_phenotype_data.csv")
# 
# # First we need to remove the effects of technical variation before removing the
# # biological covariates
# processed <- remove_technical_variation(exported)
# tech_qc <- processed$biomarkers
# 
# # Write out all the component results as above
# fwrite(tech_qc, file="path/to/nmr_biomarker_data.csv")
# fwrite(processed$biomarker_qc_flags, file="path/to/nmr_biomarker_qc_flags.csv")
# fwrite(processed$sample_processing, file="path/to/nmr_sample_qc_flags.csv")
# fwrite(processed$log_offset, file="path/to/nmr_biomarker_log_offset.csv")
# fwrite(processed$outlier_plate_detection, file="path/to/outlier_plate_info.csv")
# 
# # Second, we can now create an additional dataset that has been adjusted for
# # age, sex, and BMI.
# 
# # First, we need to extract the relevant fields from UK biobank and format as
# # above, assuming the relevant fields for age (field #21003), sex (field #31),
# # and BMI (field #21001) have also been saved by the Table Exporter tool in
# # path/to/exported_ukbiobank_phenotype_data.csv
# baseline_covar <- exported[, .(eid, age=p21003_i0, sex=p31_i0, bmi=p21001_i0)]
# repeat_covar <- exported[, .(eid, age=p21003_i1, sex=p31_i1, bmi=p21001_i1)]
# covar <- rbind(idcol="visit_index", "0"=baseline_covar, "1"=repeat_covar)
# covar[, visit_index := as.integer(visit_index)]
# 
# # Combine covariates with processed NMR biomarker data. Filter the processed
# # biomarkers only to the non-derived set, as we will plan to rederive the sums
# # and ratios after adjusting for age sex and bmi
# non_derived <- ukbnmr::nmr_info[Type == "Non-derived", Biomarker]
# non_derived <- intersect(non_derived, names(nmr)) # In case some biomarkers are not in the data
# bio_qc <- tech_qc[, .SD, .SDcols=c("eid", "visit_index", non_derived)]
# bio_qc <- covar[bio_qc, on = .(eid, visit_index), nomatch=0]
# 
# # Transform to long format so we can operate on all biomarkers in bulk
# bio_qc <- melt(bio_qc, id.vars=c("eid", "visit_index", "age", "sex", "bmi"),
#   variable.name="biomarker")
# 
# # Log transform biomarkers prior to adjustment. To do so, we need to add a small
# # offset to any measurements equal to 0. This code is copied directly from the
# # internals of the remove_technical_variation() function
# log_offset <- bioqc[!is.na(value),
#   .(Minimum=min(value), Minimum.Non.Zero=min(value[value != 0])),
#   by=biomarker]
# log_offset[, Log.Offset := ifelse(Minimum == 0, Minimum.Non.Zero / 2, 0)]
# bio_qc[log_offset, on = .(biomarker), log_value := log(value + Log.Offset)]
# 
# # Now adjust for age, sex, and (log) BMI using robust linear regression from the MASS package
# bio_qc[, adjusted := rlm(biomarker ~ age + factor(sex) + log(bmi))$residuals, by=biomarker]
# 
# # The adjusted residuals are normally distributed with mean 0. We can rescale to
# # absolute units by subtracting the mean of the original log concentrations, then
# # undoing the log transformation. This code is copied directly from the internals
# # of the remove_technical_variation() function.
# bio_qc[, adjusted := adjusted + as.vector(coef(rlm(value ~ 1)))[1], by=biomarker]
# bio_qc[, adjusted := exp(adjusted)]
# bio_qc[log_offset, on = .(biomarker), adjusted := adjusted - Log.Offset] # remove log offset
# 
# # Some values that were 0 are now < 0, apply small right shift for these biomarkers
# # (the shift should be very small, essentially numeric error. This is worth double
# # checking!). Again, this code is copied directly from the internals of the
# # remove_technical_variation() function.
# shift <- bio_qc[, .(Right.Shift=-pmin(0, min(adjusted))), by=biomarker]
# log_offset <- log_offset[shift, on = .(biomarker)]
# bio_qc[log_offset, on = .(biomarker), adjusted := adjusted + Right.Shift]
# 
# # Cast back to wide format so that each biomarker has its own column
# bioqc <- dcast(bio_qc, eid + visit_index ~ biomarker, value.var="adjusted")
# 
# # Now we recompute the composite biomarkers and derived ratios and save the result.
# bio_qc <- recompute_derived_biomarkers(bio_qc)
# fwrite(bio_qc, file="path/to/nmr_biomarkers_adjusted_for_covariates.csv")
# 
# # You may also want to aggregate and save the quality control flags for each sample from
# # the biomarkers underlying each derived biomarker or ratio, adding them as additional
# # columns to the input data (see help("recompute_derived_biomarker_qc_flags")).
# biomarker_qc_flags <- recompute_derived_biomarker_qc_flags(nmr)
# fwrite(biomarker_qc_flags, file="path/to/biomarker_qc_flags.csv")

