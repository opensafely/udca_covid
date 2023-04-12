from cohortextractor import filter_codes_by_category, patients, combine_codelists
from codelists import *
from datetime import datetime, timedelta

# This script finds each prescription date for all people identified in study_definition_pbc
# The first prescription after the start of follow-up is identified, then the next
# prescription after the previous one identified.
# The number of iterations is based on the maximum value counted in the variable udca_count_fu in the study definition
def consecutive_drugs_x(name, index_date, n, codelist):
    def var_signature(name, on_or_after, codelist):
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
    variables=var_signature(f"{name}_1", codelist, index_date)
    for i in range(2, n+1):
        variables.update(var_signature(f"{name}_{i}", codelist, f"{name}_{i-1}"))

    
    return variables_udca