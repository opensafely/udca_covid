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
COHORT = "output/input_flowchart.csv"

study = StudyDefinition(
    default_expectations={
        "date": {"earliest": "1900-01-01", "latest": "today"},
        "rate": "uniform",
        "incidence" : 0.5,
    },
    population=patients.which_exist_in_file(COHORT), 
    index_date="2020-03-01",

    # STP
    stp=patients.registered_practice_as_of(
            "index_date",
            returning="stp_code",
            return_expectations={
               "category": {"ratios": {"STP1": 0.3, "STP2": 0.2, "STP3": 0.5}},
            },
    ),
) 