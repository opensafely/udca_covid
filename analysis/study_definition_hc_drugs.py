from cohortextractor import (
    StudyDefinition,
    patients,
    codelist_from_csv,
    codelist,
    filter_codes_by_category,
    combine_codelists
)

from codelists import *
from datetime import datetime, timedelta

# Use cohort identified in study_definition_pbc.py
COHORT = "output/input_pbc.csv"

# This script uses additional terms to identify OCA and UDCA in high cost drugs data

study = StudyDefinition(
    default_expectations={
        "date": {"earliest": "1900-01-01", "latest": "today"},
        "rate": "uniform",
        "incidence" : 0.5,
    },
    population=patients.which_exist_in_file(COHORT), 
    index_date="2019-03-01",

    prescribed_oca_n = patients.with_high_cost_drugs(
        drug_name_matches="oca_codes",
        returning="binary_flag",
        on_or_after="2019-09-01",
    ),

    prescribed_udca_hcd = patients.with_high_cost_drugs(
        drug_name_matches="udca_codes",
        returning="binary_flag",
        on_or_after="2019-09-01",
    ),
)