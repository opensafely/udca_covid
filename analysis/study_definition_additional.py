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

#from variables_udca import consecutive_drugs_x
#variables_udca = consecutive_drugs_x(udca, "index_date", udca_codes, 20)
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
    index_date="2020-03-01",

    **consecutive_drugs_x(
        name="udca",
        codelist=udca_codes,
        index_date="index_date",
        n=20,
        return_expectations={
            "date": {"earliest": "2020-03-01", "latest": "today"}
        },
    ),
) 
