# Data Sources

## Genentech Cell Screening Initiative (gCSI) Dataset

### Overview

The Genentech Cell Screening Initiative (gCSI) is a pharmacogenomic resource that contains drug sensitivity data across multiple cancer cell lines. This dataset provides valuable insights into the response of cancer cells to various therapeutic agents, enabling the identification of potential biomarkers for drug sensitivity and resistance.

### External Data Sources

#### Cell Line Information

- **Name**: gCSI Cell Line Annotations
- **Version/Date**: 2013
- **URL**: https://pharmacodb.pmgenomics.ca/downloads (Original source: Genentech)
- **Access Method**: Direct download
- **Data Format**: Tab-separated values (TSV)
- **Citation**: Haverty, P.M., Lin, E., Tan, J., et al. (2016). Reproducible pharmacogenomic profiling of cancer cell line panels. Nature, 533(7603), 333-337. https://doi.org/10.1038/nature17987
- **License**: [Genentech Terms of Use](https://www.gene.com/terms-of-use)

#### Treatment Information

- **Name**: gCSI Drug Annotations
- **Version/Date**: 2013
- **URL**: https://pharmacodb.pmgenomics.ca/downloads (Original source: Genentech)
- **Access Method**: Direct download
- **Data Format**: Tab-separated values (TSV)
- **Citation**: Same as cell line information
- **License**: [Genentech Terms of Use](https://www.gene.com/terms-of-use)

#### Drug Response Data

- **Name**: gCSI Drug Response Data
- **Version/Date**: 2013
- **URL**: https://pharmacodb.pmgenomics.ca/downloads (Original source: Genentech)
- **Access Method**: Direct download
- **Data Format**: Comma-separated values (CSV)
- **Citation**: Same as cell line information
- **License**: [Genentech Terms of Use](https://www.gene.com/terms-of-use)

### Processed Data

#### Sample Metadata (sampleMetadata.tsv)

- **Name**: Preprocessed Sample Metadata
- **Input Data**: gCSI Cell Line Annotations
- **Processing Scripts**: `workflow/scripts/R/preprocessMetadata.R`
- **Output Location**: `metadata/sampleMetadata.tsv`

| Column Name            | Description                    | Example Values            |
| ---------------------- | ------------------------------ | ------------------------- |
| gCSI.CellLineName      | Original cell line name        | MC116, SK-BR-3, SU-DHL-1  |
| gCSI.PrimaryTissue     | Primary tissue of origin       | Lymph Node, Breast, Blood |
| gCSI.Norm_CellLineName | Normalized cell line name      | MC116, SKBR3, SUDHL1      |
| sampleid               | Standardized sample identifier | MC116, SK-BR-3, SU-DHL-1  |

#### Treatment Metadata (treatmentMetadata.tsv)

- **Name**: Preprocessed Treatment Metadata
- **Input Data**: gCSI Drug Annotations
- **Processing Scripts**: `workflow/scripts/R/preprocessMetadata.R`
- **Output Location**: `metadata/treatmentMetadata.tsv`

| Column Name        | Description               | Example Values                       |
| ------------------ | ------------------------- | ------------------------------------ |
| gCSI.DrugName      | Original drug name        | Vinblastine, Vincristine, Paclitaxel |
| gCSI.Norm_DrugName | Normalized drug name      | VINBLASTINE, VINCRISTINE, PACLITAXEL |
| treatmentid        | Standardized treatment ID | Vinblastine, Vincristine, Paclitaxel |

#### Treatment Response: Profiles

- **Name**: Preprocessed Treatment Response Profiles
- **Input Data**: gCSI Drug Response Data
- **Processing Scripts**: `workflow/scripts/R/preprocessTreatmentResponse.R`
- **Output Location**: `data/procdata/preprocessed_TreatmentResponse_profiles.csv`

| Column Name      | Description                          | Units/Notes                                      |
| ---------------- | ------------------------------------ | ------------------------------------------------ |
| treatmentid      | Drug identifier                      | Same as `treatmentid` in metadata                |
| sampleid         | Cell line identifier                 | Same as `sampleid` in metadata                   |
| ExperimentNumber | Identifier for the experiment        | 2c, 2d, etc.                                     |
| meanviability    | Mean viability across concentrations | Percentage                                       |
| GR_AOC           | Growth Rate Area Over Curve          | Metric for overall drug effect                   |
| GRmax            | Maximum growth rate inhibition       | Negative values indicate growth inhibition       |
| Emax             | Maximum effect level                 | Percentage inhibition at highest concentration   |
| GRinf            | GR value at infinite concentration   | Growth rate inhibition at infinite concentration |
| GEC50            | Half maximal effective concentration | μM (micromolar), based on GR metrics             |
| GR50             | Concentration at GR value of 0.5     | μM (micromolar)                                  |
| R_square_GR      | R-squared for GR curve fitting       | Measure of fit quality, values from 0 to 1       |
| pval_GR          | P-value for GR curve fitting         | Statistical significance of the curve fit        |
| flat_fit_GR      | Flat fit flag for GR curve           | 0 (not flat) or 1 (flat fit)                     |
| h_GR             | Hill slope for GR curve              | Steepness of the dose-response curve             |

#### Treatment Response: Raw

- **Name**: Preprocessed Raw Treatment Response
- **Input Data**: gCSI Drug Response Data
- **Processing Scripts**: `workflow/scripts/R/preprocessTreatmentResponse.R`
- **Output Location**: `data/procdata/preprocessed_TreatmentResponse_raw.csv`

| Column Name      | Description                    | Units/Notes                             |
| ---------------- | ------------------------------ | --------------------------------------- |
| treatmentid      | Drug identifier                | Same as `treatmentid` in metadata       |
| sampleid         | Cell line identifier           | Same as `sampleid` in metadata          |
| tissue           | Tissue of origin               | Lymph Node, Breast, Blood, etc.         |
| ExperimentNumber | Identifier for the experiment  | 2b, 2c, 2d, etc.                        |
| TrtDuration      | Treatment duration             | Hours                                   |
| doublingtime     | Cell line doubling time        | Hours                                   |
| dose             | Drug concentration             | μM (micromolar)                         |
| viability        | Cell viability at given dose   | Percentage, values relative to control  |
| GR               | Growth rate value              | Growth rate-adjusted drug effect        |
| activities.mean  | Mean activity                  | Mean percentage of inhibition or growth |
| activities.std   | Standard deviation of activity | Standard deviation of percentage values |
