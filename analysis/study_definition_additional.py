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

COHORT = "output/input_pbc.csv"

# This script finds each prescription date for all people identified in study_definition_pbc
# The number of iterations is based on the maximum value counted in the variable udca_count_fu in the study definition
# To update as 334 is maximum (duplicates?) sticking with 40 for now = 1 per month plus leeway
# Index date is first January 2020 to make sure have exposure status correct at 1st March 2020
def consecutive_drugs_x(name, codelist, index_date, n, return_expectations):
    def var_signature(name, codelist, on_or_after, return_expectations):
        return {
           name: patients.with_these_medications(
            codelist,
            returning="date",
            on_or_after=on_or_after,
            return_first_date_in_period=True,
            date_format="YYYY-MM-DD", 
            return_expectations=return_expectations
        )
        }  
    variables=var_signature(f"{name}_1", codelist, index_date, return_expectations)
    for i in range(2, n+1):
        variables.update(var_signature(f"{name}_{i}", codelist, f"{name}_{i-1}", return_expectations))
    return variables

study = StudyDefinition(
    default_expectations={
        "date": {"earliest": "1900-01-01", "latest": "today"},
        "rate": "uniform",
        "incidence" : 0.5,
    },
    population=patients.which_exist_in_file(COHORT), 
    index_date="2020-01-01",

    **consecutive_drugs_x(
        name="udca",
        codelist=udca_codes,
        index_date="index_date",
        n=40,
        return_expectations={
            "date": {"earliest": "2020-03-01", "latest": "today"}
        },
    ),
) 
