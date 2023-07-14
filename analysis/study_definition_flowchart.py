from cohortextractor import (
    StudyDefinition,
    patients,
)
from codelists import *

study = StudyDefinition(
    default_expectations={
        "date": {"earliest": "1980-01-01", "latest": "today"},
        "rate": "uniform",
        "incidence": 0.05,
    },
    index_date="2020-03-01",
    population=patients.all(),
        #  has_follow_up 
        # (age >=18 AND age <= 110) AND
        # (NOT died) AND
        # (sex = 'M' OR sex = 'F') AND
        # (imd != 0) AND
        # (has_pbc=1 OR has_psc=1) AND
        # (NOT liver_transplant_bl)

    has_follow_up=patients.registered_with_one_practice_between(
            "index_date - 6 months", "index_date"
    ),
    died=patients.died_from_any_cause(
        on_or_before="index_date"
    ),
    # Age
    age=patients.age_as_of(
            "index_date",
            return_expectations={
                "rate": "universal",
                "int": {"distribution": "population_ages"},
            },
        ),
    # Sex
    sex=patients.sex(
        return_expectations={
            "rate": "universal",
            "category": {"ratios": {"M": 0.49, "F": 0.5, "U": 0.01}},
        },
    ),
    #IMD
     has_msoa=patients.satisfying(
        "NOT (msoa = '')",
            msoa=patients.address_as_of(
            "2019-04-01",
            returning="msoa",
            ),
    return_expectations={"incidence": 0.95}
    ),
    imd=patients.categorised_as(
        {
        "0": "DEFAULT",
        "1": """index_of_multiple_deprivation >=0 AND index_of_multiple_deprivation < 32844*1/5 AND has_msoa""",
        "2": """index_of_multiple_deprivation >= 32844*1/5 AND index_of_multiple_deprivation < 32844*2/5""",
        "3": """index_of_multiple_deprivation >= 32844*2/5 AND index_of_multiple_deprivation < 32844*3/5""",
        "4": """index_of_multiple_deprivation >= 32844*3/5 AND index_of_multiple_deprivation < 32844*4/5""",
        "5": """index_of_multiple_deprivation >= 32844*4/5 AND index_of_multiple_deprivation <= 32844""",
        },
    index_of_multiple_deprivation=patients.address_as_of(
        "2019-04-01",
        returning="index_of_multiple_deprivation",
        round_to_nearest=100,
        ),
    return_expectations={
        "rate": "universal",
        "category": {
            "ratios": {
                "0": 0.05,
                "1": 0.19,
                "2": 0.19,
                "3": 0.19,
                "4": 0.19,
                "5": 0.19,
                }
            },
        },
    ),

    # Has PBC or PSC diagnosis
    has_pbc=patients.with_these_clinical_events(
        pbc_codes,
        returning = "binary_flag",
        include_date_of_match = "True",
        on_or_before = "index_date - 6 months"
    ),
    has_psc=patients.with_these_clinical_events(
        psc_codes,
        returning = "binary_flag",
        include_date_of_match = "True",
        on_or_before = "index_date - 6 months"
    ),

    # Liver transplant
    liver_transplant_bl=patients.satisfying(
      """
      bl_liver_transplant_snomed OR
      bl_liver_transplant_opcs
      """,
      bl_liver_transplant_snomed=patients.with_these_clinical_events(
        liver_transplant_snomed_codes,
        returning = "binary_flag",
        on_or_before = "index_date"
      ),
      bl_liver_transplant_opcs=patients.admitted_to_hospital(
        on_or_before = "index_date",
        with_these_procedures = liver_transplant_opcs_codes,
        returning = "binary_flag",
      ),
    ),
)
