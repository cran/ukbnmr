% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/biomarker_qc.R
\name{remove_technical_variation}
\alias{remove_technical_variation}
\title{Remove technical variation from NMR biomarker data in UK Biobank.}
\usage{
remove_technical_variation(
  x,
  remove.outlier.plates = TRUE,
  skip.biomarker.qc.flags = FALSE,
  version = 3L
)
}
\arguments{
\item{x}{\code{data.frame} containing a tabular phenotype dataset extracted by the
\href{https://dnanexus.gitbook.io/uk-biobank-rap/working-on-the-research-analysis-platform/accessing-data/accessing-phenotypic-data#create-a-tsv-or-csv-file-using-table-exporter}{Table Exporter} tool on the
\href{https://ukbiobank.dnanexus.com/landing}{UK Biobank Research Analysis Platform}
containing the project specific sample id (eid) and all fields (and instances)
relating to the NMR metabolomics data (i.e. fields listed in showcase categories
\href{https://biobank.ndph.ox.ac.uk/showcase/label.cgi?id=220}{220},
\href{https://biobank.ndph.ox.ac.uk/showcase/label.cgi?id=221}{221}, and
\href{https://biobank.ndph.ox.ac.uk/showcase/label.cgi?id=222}{222}.}

\item{remove.outlier.plates}{logical, when set to \code{FALSE} biomarker
concentrations on outlier shipment plates (see details) are not set to
missing but simply flagged in the \code{biomarker_qc_flags} \code{data.frame}
in the returned \code{list}.}

\item{skip.biomarker.qc.flags}{logical, when set to \code{TRUE} biomarker QC
flags are not processed or returned.}

\item{version}{version of the QC algorithm to apply. Defaults to 3, the latest
version of the algorithm (see details).}
}
\value{
a \code{list} containing three \code{data.frames}: \describe{
  \item{biomarkers}{A \code{data.frame} with column names "eid",
       and "visit_index", containing project-specific sample identifier and
       UK Biobank visit index (0 for baseline assessment, 1 for first repeat
       assessment), followed by columns for each biomarker containing their
       absolute concentrations (or ratios thereof) adjusted for technical
       variation. See \code{\link{nmr_info}} for information on each biomarker.}
  \item{biomarker_qc_flags}{A \code{data.frame} with the same format as
        \code{biomarkers} with entries corresponding to the
        \href{https://biobank.ndph.ox.ac.uk/showcase/label.cgi?id=221}{quality
        control indicators} for each sample. "High plate outlier" and "Low
        plate outlier" indicate the value was set to missing due to systematic
        abnormalities in the biomarker's concentration on the sample's shipment
        plate compared to all other shipment plates (see Details). For
        composite and derived biomarkers, quality control flags are aggregates
        of any quality control flags for the underlying biomarkers from which
        the composite biomarker or ratio is derived.}
  \item{sample_processing}{A \code{data.frame} containing the
        \href{https://biobank.ndph.ox.ac.uk/showcase/label.cgi?id=222}{processing
        information and quality control indicators} for each sample, including
        those derived for removal of unwanted technical variation by this
        function. See \code{\link{sample_qc_info}} for details.}
  \item{log_offset}{A \code{data.frame} containing diagnostic information on
        the offset applied so that biomarkers with concentrations of 0 could
        be log transformed, and any right shift applied to prevent negative
        concentrations after rescaling adjusted residuals back to absolute
        concentrations. Should contain only biomarkers with minimum
        concentrations of 0 (in the "Minimum" column). "Minimum.Non.Zero"
        gives the smallest non-zero concentration for the biomarker.
        "Log.Offset" the small offset added to all samples prior to
        log transformation: half the mininum non-zero concentration.
        "Right.Shift" gives the small offset added to prevent negative
        concentrations that arise after rescaling residuals to log
        concentrations: this should be at least one order of magnitude
        smaller than the smallest non-zero value (i.e. the offset added
        should amount to noise in numeric precision for all samples). See
        publication for more details.}
  \item{outlier_plate_detection}{A \code{data.frame} containing diagnostic
        information and details of outlier plate detection. For each of the
        107 non-derived biomarkers, the median concentration on each of the
        1,352 plates was calculated, then plates were flagged as outliers if
        their median value deviated more than expected from the mean of plate
        medians. "Mean.Plate.Medians" gives the mean of the plate medians for
        each biomarker. "Lower.Limit" and "Upper.Limit" give the values below
        and above which plates are flagged as outliers based on their plate
        median. See publication for more details.}
  \item{algorithm_version}{Version of the algorithm run, either 1, 2, or 3
        (default).}
}
}
\description{
Remove technical variation from NMR biomarker data in UK Biobank.
}
\details{
Three versions of the QC algorithm have been developed. Version 1 was designed
based on the first phase of data released to the public covering ~120,000
UK Biobank participants. Version 2 made several improvements to the algorithm
based on the subsequent second public release of data covering an additional
~150,000 participants. Version 3, the default, makes some further minor tweaks
primarily so that the algorithm is compatible with the full public data
release covering all ~500,000 participants.

Details on the impact of these algorithms on technical variation in the latest
UK Biobank data are provided in the package vignette and on the github readme.

## Version 1
Setting version to 1 applies the algorithm as exactly described in Ritchie S.
C. *et al.* _Sci Data_ 2023. In brief, this multi-step procedure applies the
following steps in sequence:

1. First biomarker data is filtered to the 107 biomarkers that cannot be
   derived from any combination of other biomarkers.
2. Absolute concentrations are log transformed, with a small offset
   applied to biomarkers with concentrations of 0.
3. Each biomarker is adjusted for the time between sample preparation
   and sample measurement (hours).
4. Each biomarker is adjusted for systematic differences between rows
   (A-H) on the 96-well shipment plates.
5. Each biomarker is adjusted for remaining systematic differences
   between columns (1-12) on the 96-well shipment plates.
6. Each biomarker is adjusted for drift over time within each of the six
   spectrometers. To do so, samples are grouped into 10 bins, within each
   spectrometer, by the date the majority of samples on their respective
   96-well plates were measured.
7. Regression residuals after the sequential adjustments are
   transformed back to absolute concentrations.
8. Samples belonging to shipment plates that are outliers of
   non-biological origin are identified and set to missing.
9. The 61 composite biomarkers and 81 biomarker ratios are recomputed
   from their adjusted parts.
10. An additional 76 biomarker ratios of potential biological
    significance are computed.

At each step, adjustment for technical covariates is performed using
\link[MASS:rlm]{robust linear regression}. Plate row, plate column, and
sample measurement date bin are treated as factors, using the group with the
largest sample size as reference in the regression.

## Version 2
Version 2 of the algorithm modifies the above procedure to (1)
adjust for well and column within each processing batch separately in steps 4
and 5, and (2) in step 6 instead of splitting samples into 10 bins per
spectrometer uses a fixed bin size of approximately 2,000 samples per bin,
ensuring samples measured on the same plate and plates measured on the same
day are grouped into the same bin.

The first modification was made as applying version 1 of the algorithm to the
combined data from the first and second tranche of measurements revealed
introduced stratification by well position when examining the corrected
concentrations in each data release separately.

The second modification was made to ensure consistent bin sizes across data
releases when correcting for drift over time. Otherwise, spectrometers used
in multiple data releases would have different bin sizes when adjusting
different releases. A bin split is also hard coded on spectrometer 5 between
plates 0490000006726 and 0490000006714 which correspond to a large change in
concentrations akin to a spectrometer recalibration event most strongly
observed for alanine concentrations.

## Version 3
Version 3 of the algorithm makes two further minor changes:

1. Imputation of missing sample preparation times has been improved. Previously,
   any samples missing time of measurement (N=3 in the phase 2 public release)
   had their time of measurement set to 00:00. In version 3, the time of measurement
   is set to the median time of measurement for that spectrometer on that day,
   which is between 12:00-13:00, instead of 00:00.
2. Underlying code for adjusting drift over time has been modified to accommodate
   the phase 3 public release, which includes one spectrometer with ~2,500 samples.
   Version 2 of the algorithm would split this into two bins, whereas version 3
   keeps this as a single bin to better match the bin sizes of the rest of the
   spectrometers.
}
\examples{
ukb_data <- ukbnmr::test_data # Toy example dataset for testing package
processed <- remove_technical_variation(ukb_data)

}
