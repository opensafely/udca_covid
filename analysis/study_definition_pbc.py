from cohortextractor import StudyDefinition, patients, codelist, codelist_from_csv, filter_codes_by_category  # NOQA

from codelists import*

study = StudyDefinition(
    default_expectations={
        "date": {"earliest": "1900-01-01", "latest": "today"},
        "rate": "uniform",
        "incidence": 0.5,
    },
    index_date="2020-03-01",
    population=patients.satisfying(
        """
        has_follow_up AND
        (age >=18 AND age <= 110) AND
        (NOT died) AND
        (sex = 'M' OR sex = 'F') AND
        (has_pbc=1 OR has_psc=1)
        """,
        has_follow_up=patients.registered_with_one_practice_between(
            "index_date - 6 months", "index_date"
        ),
        died=patients.died_from_any_cause(
            on_or_before="index_date"
        ),
    ),
    dereg_date=patients.date_deregistered_from_all_supported_practices(
        on_or_after="index_date",
        date_format="YYYY-MM-DD",
        return_expectations={"date": {"earliest": "2020-03-01"}}
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
    # STP
    stp=patients.registered_practice_as_of(
            "index_date",
            returning="stp_code",
            return_expectations={
               "category": {"ratios": {"STP1": 0.3, "STP2": 0.2, "STP3": 0.5}},
            },
    ),
    region_nhs = patients.registered_practice_as_of(
        "index_date",
        returning = "nuts1_region_name",
        return_expectations = {
        "rate": "universal",
        "category": {
        "ratios": {
        "North East": 0.1,
        "North West": 0.1,
        "Yorkshire and The Humber": 0.1,
        "East Midlands": 0.1,
        "West Midlands": 0.1,
        "East": 0.1,
        "London": 0.2,
        "South West": 0.1,
        "South East": 0.1,},},
        },
        ),
    #Ethnicity
    eth=patients.with_these_clinical_events(
                ethnicity_codes,
                returning="category",
                find_last_match_in_period=True,
                include_date_of_match=False,
                return_expectations={
                    "category": {"ratios": {"1": 0.2, "2": 0.2, "3": 0.2, "4": 0.2, "5": 0.2}},
                    "incidence": 1.00,
                     },
                ),
            # fill missing ethnicity from SUS
        ethnicity_sus=patients.with_ethnicity_from_sus(
                returning="group_6",
                use_most_frequent_code=True,
                return_expectations={
                    "category": {"ratios": {"1": 0.2, "2": 0.2, "3": 0.2, "4": 0.2, "5": 0.2}},
                    "incidence": 1.00,
                },
            ),
        ethnicity=patients.categorised_as(
            {"0": "DEFAULT",
                "1": "eth='1' OR (NOT eth AND ethnicity_sus='1')",
                "2": "eth='2' OR (NOT eth AND ethnicity_sus='2')",
                "3": "eth='3' OR (NOT eth AND ethnicity_sus='3')",
                "4": "eth='4' OR (NOT eth AND ethnicity_sus='4')",
                "5": "eth='5' OR (NOT eth AND ethnicity_sus='5')",
            },
            return_expectations={
                "category": {"ratios": {"0": 0.05, "1": 0.15, "2": 0.2, "3": 0.2, "4": 0.2, "5": 0.2}},
                "incidence": 1.0,
                    },
        ),
     smoking_status=patients.categorised_as(
        {
            "S": "most_recent_smoking_code = 'S'",
            "E": """
                     most_recent_smoking_code = 'E' OR (    
                       most_recent_smoking_code = 'N' AND ever_smoked   
                     )  
                """,
            "N": "most_recent_smoking_code = 'N' AND NOT ever_smoked",
            "M": "DEFAULT",
        },
        return_expectations={
            "category": {"ratios": {"S": 0.4, "E": 0.3, "N": 0.2, "M": 0.1}}
            },
        most_recent_smoking_code=patients.with_these_clinical_events(
            clear_smoking_codes,
            find_last_match_in_period=True,
            on_or_before="index_date",
            returning="category",
            ),
        ever_smoked=patients.with_these_clinical_events(
            filter_codes_by_category(clear_smoking_codes, include=["S", "E"]),
            on_or_before="index_date",
            ),
        ),
    # Has PBC or PSC diagnosis
    has_pbc=patients.with_these_clinical_events(
        pbc_codes,
        returning = "binary_flag",
        include_date_of_match = "True",
        on_or_before = "index_date"
    ),
    has_psc=patients.with_these_clinical_events(
        psc_codes,
        returning = "binary_flag",
        include_date_of_match = "True",
        on_or_before = "index_date"
    ),

    #Ursodeoxycholic acid 
    udca_count=patients.with_these_medications(
        udca_codes, 
        between=["2019-09-01", "2020-02-29"],
        returning="number_of_matches_in_period",
        return_expectations={
            "int": {"distribution": "normal", "mean": 3, "stddev": 2},
            "incidence": 0.30,
        },
    ),

     udca_last_date=patients.with_these_medications(
        udca_codes, 
        between=["2019-09-01", "2020-02-29"], 
        return_last_date_in_period=True,
        date_format="YYYY-MM-DD",
        return_expectations={
            "date": {"earliest": "2019-09-01", "latest": "2020-02-29"}
        },
    ),

    udca_first_after=patients.with_these_medications(
        udca_codes, 
        on_or_after="2020-03-01",
        return_first_date_in_period=True,
        date_format="YYYY-MM-DD",
        return_expectations={
            "date": {"earliest": "2020-03-01", "latest": "today"}
        },
    ),
    
    #HISTORY OF UDCA use
    udca_first_history=patients.with_these_medications(
        udca_codes, 
        on_or_before="2020-02-29",
        return_first_date_in_period=True,
        date_format="YYYY-MM-DD",
        return_expectations={
            "date": {"latest": "2020-02-29"}
        },
    ),

    udca_count_fu=patients.with_these_medications(
        udca_codes, 
        between=["2020-03-01", "2022-12-31"],
        returning="number_of_matches_in_period",
        return_expectations={
            "int": {"distribution": "normal", "mean": 3, "stddev": 2},
            "incidence": 0.30,
        },
    ),

    #obeticholic acid prescribing high cost drugs
    oba=patients.with_high_cost_drugs(
        drug_name_matches="obeticholic acid",
        returning="binary_flag",
        on_or_after="2019-09-01",
    ),

    #OUTCOMES
     died_ons_covid_flag_any=patients.with_these_codes_on_death_certificate(
        covid_identification,
        on_or_after="2020-03-01",
        match_only_underlying_cause=False,
        returning="binary_flag",
        return_expectations={"date": {"earliest": "2020-03-01"}},
    ),
    died_ons_covid_flag_underlying=patients.with_these_codes_on_death_certificate(
        covid_identification,
        on_or_after="2020-03-01",
        match_only_underlying_cause=True,
        returning="binary_flag",
        return_expectations={"date": {"earliest": "2020-03-01"}},
    ),
    died_date_ons=patients.died_from_any_cause(
        on_or_after="2020-03-01",
        returning="date_of_death",
        date_format="YYYY-MM-DD",
        return_expectations={"date": {"earliest": "2020-03-01"}},
    ),
    
)   