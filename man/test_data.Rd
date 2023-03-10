% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/data.R
\docType{data}
\name{test_data}
\alias{test_data}
\title{Data for testing package functions}
\format{
A data table with 50 rows and 735 columns with column names "eid"
followed by extracted UK Biobank field data of the format "23649-0.0",
"23649-1.0", \dots, "23655-1.0".
}
\source{
Data in each column has been randomly drawn from the distribution
present in the UK Biobank dataset. Importantly, random sampling was performed
for each column separately, thus no rows represent real observations or
participants in UK Biobank.
}
\usage{
test_data
}
\description{
Dataset mimicking structure of decoded UK Biobank dataset of NMR metabolomics
biomarker concentrations and associated processing variables for testing
package functions.
}
\keyword{datasets}
