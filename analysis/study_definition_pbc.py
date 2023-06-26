from cohortextractor import StudyDefinition, patients, codelist, codelist_from_csv, filter_codes_by_category, combine_codelists  # NOQA

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
        (has_pbc=1 OR has_psc=1) AND
        (NOT bl_liver_transplant)
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

     bmi=patients.most_recent_bmi(
        between=["2010-03-01", "2020-03-01"],
        minimum_age_at_measurement=16,
        return_expectations={
            "date": {"earliest": "2010-02-01", "latest": "2020-01-31"},
            "float": {"distribution": "normal", "mean": 28, "stddev": 8},
            "incidence": 0.80,
        }
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

    liver_transplant_fu=patients.satisfying(
      """
      fu_liver_transplant_snomed OR
      fu_liver_transplant_opcs
      """,
      fu_liver_transplant_snomed=patients.with_these_clinical_events(
        liver_transplant_snomed_codes,
        returning = "date",
        date_format = "YYYY-MM-DD",
        on_or_after = "index_date",
        find_first_match_in_period = "True",
      ),
      fu_liver_transplant_opcs=patients.admitted_to_hospital(
        on_or_after = "index_date",
        with_these_procedures = liver_transplant_opcs_codes,
        returning = "date_admitted",
        date_format = "YYYY-MM-DD",
        find_first_match_in_period = "True",
      ),
    ),

    #Ursodeoxycholic acid 
    udca_count_bl=patients.with_these_medications(
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
    oca_bl=patients.with_high_cost_drugs(
        drug_name_matches="obeticholic acid",
        returning="binary_flag",
        on_or_after="2019-09-01",
    ),

    # Budenoside prescribing
    budesonide_count_fu=patients.with_these_medications(
        budesonide_codes,
        between=["2020-03-01", "2022-12-31"],
        returning="number_of_matches_in_period",
        return_expectations={
            "int": {"distribution": "normal", "mean": 3, "stddev": 2},
            "incidence": 0.30,
        },
    ),

    budesonide_count_bl=patients.with_these_medications(
        budesonide_codes,
        between=["2020-02-29", "2019-09-01"],
        returning="number_of_matches_in_period",
        return_expectations={
            "int": {"distribution": "normal", "mean": 3, "stddev": 2},
            "incidence": 0.30,
        },
    ),

    # Fenofibrate prescribing
    fenofibrate_count_fu=patients.with_these_medications(
        fenofibrate_codes,
        between=["2020-03-01", "2022-12-31"],
        returning="number_of_matches_in_period",
        return_expectations={
            "int": {"distribution": "normal", "mean": 3, "stddev": 2},
            "incidence": 0.30,
        },
    ),

    fenofibrate_count_bl=patients.with_these_medications(
        fenofibrate_codes,
        between=["2020-02-29", "2019-09-01"],
        returning="number_of_matches_in_period",
        return_expectations={
            "int": {"distribution": "normal", "mean": 3, "stddev": 2},
            "incidence": 0.30,
        },
    ),

    # Steroid prescribing
    gc_count_fu=patients.with_these_medications(
        gc_codes,
        between=["2020-03-01", "2022-12-31"],
        returning="number_of_matches_in_period",
        return_expectations={
            "int": {"distribution": "normal", "mean": 3, "stddev": 2},
            "incidence": 0.30,
        },
    ),

    gc_count_bl=patients.with_these_medications(
        gc_codes,
        between=["2020-02-29", "2019-09-01"],
        returning="number_of_matches_in_period",
        return_expectations={
            "int": {"distribution": "normal", "mean": 3, "stddev": 2},
            "incidence": 0.30,
        },
    ),

    # rituximab prescribing high cost drugs
    rituximab_bl=patients.with_high_cost_drugs(
        drug_name_matches="rituximab",
        returning="binary_flag",
        on_or_after="2019-09-01",
    ),

    # COVID vaccination
    covid_vacc_date=patients.with_tpp_vaccination_record(
        target_disease_matches="SARS-2 CORONAVIRUS",
        on_or_after="2020-12-01",  # check all december to date
        find_first_match_in_period=True,
        returning="date",
        date_format="YYYY-MM-DD",
        return_expectations={
            "date": {
                "earliest": "2020-12-08",  # first vaccine administered on the 8/12
                "latest": "2022-12-31",
            },
            "incidence": 0.9,
        },
    ),

    # Disease severity
    # Snomed codelist to be updated - awaiting tech support
    severe_disease_bl = patients.satisfying(
        """
        severe_disease_bl_snomed OR
        severe_disease_bl_icd
        """,
        severe_disease_bl_snomed=patients.with_these_clinical_events(
            severe_disease_codes_snomed,
            on_or_before="index_date",
            returning="binary_flag",
        ),
        severe_disease_bl_icd=patients.admitted_to_hospital(
            with_these_diagnoses=severe_disease_codes_icd,
            on_or_before="index_date",
            returning="binary_flag",
        ),
    ),
           
    severe_disease_fu_snomed=patients.with_these_clinical_events(
        severe_disease_codes_snomed,
        on_or_after="index_date",
        returning="date",
        date_format="YYYY-MM-DD",
        find_first_match_in_period = True,
        return_expectations={"date": {"earliest": "2020-03-01"}},
    ),
    severe_disease_fu_icd=patients.admitted_to_hospital(
        with_these_diagnoses=severe_disease_codes_icd,
        on_or_after="index_date",
        returning="date_admitted",
        date_format="YYYY-MM-DD",
        find_first_match_in_period = True,
        return_expectations={"date": {"earliest": "2020-03-01"}},
    ),
    severe_disease_fu_date = patients.minimum_of("severe_disease_fu_snomed", "severe_disease_fu_icd"),

    # COVID-19 high risk conditions 

     ## Learning disability
  learning_disability_nhsd_snomed = patients.with_these_clinical_events(
    learning_disability_snomed_codes,
    on_or_before = "index_date",
    returning = "binary_flag",
  ),
  
  ## Solid cancer
  cancer_opensafely_snomed = patients.with_these_clinical_events(
    combine_codelists(
      non_haematological_cancer_opensafely_snomed_codes,
      lung_cancer_opensafely_snomed_codes,
      chemotherapy_radiotherapy_opensafely_snomed_codes
    ),
    between = ["index_date - 6 months", "index_date"],
    returning = "binary_flag",
  ),
  ## Solid cance-updated  
  cancer_opensafely_snomed_new = patients.with_these_clinical_events(
    combine_codelists(
      non_haematological_cancer_opensafely_snomed_codes_new,
      lung_cancer_opensafely_snomed_codes,
      chemotherapy_radiotherapy_opensafely_snomed_codes
    ),
    between = ["index_date - 6 months", "index_date"],
    returning = "binary_flag",
  ),    
  cancer_opensafely_snomed_ever = patients.with_these_clinical_events(
    combine_codelists(
      non_haematological_cancer_opensafely_snomed_codes_new,
      lung_cancer_opensafely_snomed_codes,
      chemotherapy_radiotherapy_opensafely_snomed_codes
    ),
    on_or_before = "index_date",
    returning = "binary_flag",
  ),    

  ## Haematological diseases
  haematopoietic_stem_cell_snomed = patients.with_these_clinical_events(
    haematopoietic_stem_cell_transplant_nhsd_snomed_codes,
    between = ["index_date - 12 months", "index_date"],
    returning = "binary_flag",
  ),
  
  haematopoietic_stem_cell_icd10 = patients.admitted_to_hospital(
    returning = "binary_flag",
    between = ["index_date - 12 months", "index_date"],
    with_these_diagnoses = haematopoietic_stem_cell_transplant_nhsd_icd10_codes,
  ),
  
  haematopoietic_stem_cell_opcs4 = patients.admitted_to_hospital(
    returning = "binary_flag",
    between = ["index_date - 12 months", "index_date"],
    with_these_procedures = haematopoietic_stem_cell_transplant_nhsd_opcs4_codes,
    return_expectations = {
      "date": {"earliest": "2020-02-01"},
      "rate": "exponential_increase",
      "incidence": 0.01,
    },
  ),
  
  haematological_malignancies_snomed = patients.with_these_clinical_events(
    haematological_malignancies_nhsd_snomed_codes,
    between = ["index_date - 24 months", "index_date"],
    returning = "binary_flag",
  ),
  
  haematological_malignancies_icd10 = patients.admitted_to_hospital(
    returning = "binary_flag",
    between = ["index_date - 24 months", "index_date"],
    with_these_diagnoses = haematological_malignancies_nhsd_icd10_codes,
  ),
  
  sickle_cell_disease_nhsd_snomed = patients.with_these_clinical_events(
    sickle_cell_disease_nhsd_snomed_codes,
    on_or_before = "index_date",
    returning = "binary_flag",
  ),
  
  sickle_cell_disease_nhsd_icd10 = patients.admitted_to_hospital(
    returning = "binary_flag",
    on_or_before = "index_date",
    with_these_diagnoses = sickle_cell_disease_nhsd_icd10_codes,
  ),
  
  haematological_disease_nhsd = patients.maximum_of("haematopoietic_stem_cell_snomed", 
                                                    "haematopoietic_stem_cell_icd10", 
                                                    "haematopoietic_stem_cell_opcs4", 
                                                    "haematological_malignancies_snomed", 
                                                    "haematological_malignancies_icd10",
                                                    "sickle_cell_disease_nhsd_snomed", 
                                                    "sickle_cell_disease_nhsd_icd10"), 
  
  haematopoietic_stem_cell_snomed_ever = patients.with_these_clinical_events(
    haematopoietic_stem_cell_transplant_nhsd_snomed_codes,
    on_or_before = "index_date",
    returning = "binary_flag",
  ),
  
  haematopoietic_stem_cell_icd10_ever = patients.admitted_to_hospital(
    returning = "binary_flag",
    on_or_before = "index_date",
    with_these_diagnoses = haematopoietic_stem_cell_transplant_nhsd_icd10_codes,
  ),
  
  haematopoietic_stem_cell_opcs4_ever = patients.admitted_to_hospital(
    returning = "binary_flag",
    on_or_before = "index_date",
    with_these_procedures = haematopoietic_stem_cell_transplant_nhsd_opcs4_codes,
  ),
  
  haematological_malignancies_snomed_ever = patients.with_these_clinical_events(
    haematological_malignancies_nhsd_snomed_codes,
    on_or_before = "index_date",
    returning = "binary_flag",
  ),
  
  haematological_malignancies_icd10_ever = patients.admitted_to_hospital(
    returning = "binary_flag",
    on_or_before = "index_date",
    with_these_diagnoses = haematological_malignancies_nhsd_icd10_codes,
  ),

  haematological_disease_nhsd_ever = patients.maximum_of("haematopoietic_stem_cell_snomed_ever", 
                                                    "haematopoietic_stem_cell_icd10_ever", 
                                                    "haematopoietic_stem_cell_opcs4_ever", 
                                                    "haematological_malignancies_snomed_ever", 
                                                    "haematological_malignancies_icd10_ever",
                                                    "sickle_cell_disease_nhsd_snomed", 
                                                    "sickle_cell_disease_nhsd_icd10"), 
  

  ## Renal disease
  ckd_stage_5_nhsd_snomed = patients.with_these_clinical_events(
    ckd_stage_5_nhsd_snomed_codes,
    on_or_before = "index_date",
    returning = "binary_flag",
  ),
  
  ckd_stage_5_nhsd_icd10 = patients.admitted_to_hospital(
    returning = "binary_flag",
    on_or_before = "index_date",
    with_these_diagnoses = ckd_stage_5_nhsd_icd10_codes,
  ),
  
  ckd_stage_5_nhsd = patients.maximum_of("ckd_stage_5_nhsd_snomed", "ckd_stage_5_nhsd_icd10"), 
  
  ## Immune-mediated inflammatory disorders (IMID)
  immunosuppresant_drugs_nhsd = patients.with_these_medications(
    codelist = combine_codelists(immunosuppresant_drugs_dmd_codes, immunosuppresant_drugs_snomed_codes),
    returning = "binary_flag",
    between = ["index_date - 6 months", "index_date"],
  ),
  
  oral_steroid_drugs_nhsd = patients.with_these_medications(
    codelist = combine_codelists(oral_steroid_drugs_dmd_codes, oral_steroid_drugs_snomed_codes),
    returning = "binary_flag",
    between = ["index_date - 12 months", "index_date"],
  ),
  
  oral_steroid_drug_nhsd_3m_count = patients.with_these_medications(
    codelist = combine_codelists(oral_steroid_drugs_dmd_codes, oral_steroid_drugs_snomed_codes),
    returning = "number_of_matches_in_period",
    between = ["index_date - 3 months", "index_date"],
    return_expectations = {"incidence": 0.1,
      "int": {"distribution": "normal", "mean": 2, "stddev": 1},
    },
  ),
  
  oral_steroid_drug_nhsd_12m_count = patients.with_these_medications(
    codelist = combine_codelists(oral_steroid_drugs_dmd_codes, oral_steroid_drugs_snomed_codes),
    returning = "number_of_matches_in_period",
    between = ["index_date - 12 months", "index_date"],
    return_expectations = {"incidence": 0.1,
      "int": {"distribution": "normal", "mean": 3, "stddev": 1},
    },
  ),
  
  # imid_nhsd = patients.minimum_of("immunosuppresant_drugs_nhsd", "oral_steroid_drugs_nhsd"), - define in processing script
  immunosuppresant_drugs_nhsd_ever = patients.with_these_medications(
    codelist = combine_codelists(immunosuppresant_drugs_dmd_codes, immunosuppresant_drugs_snomed_codes),
    returning = "binary_flag",
    on_or_before = "index_date",
  ),
  
  oral_steroid_drugs_nhsd_ever = patients.with_these_medications(
    codelist = combine_codelists(oral_steroid_drugs_dmd_codes, oral_steroid_drugs_snomed_codes),
    returning = "binary_flag",
    on_or_before = "index_date",
  ),  
  
  ## Primary immune deficiencies
  immunosupression_nhsd = patients.with_these_clinical_events(
    immunosupression_nhsd_codes,
    on_or_before = "index_date",
    returning = "binary_flag",
  ),
  ## Primary immune deficiencies-updated
  immunosupression_nhsd_new = patients.with_these_clinical_events(
    immunosupression_nhsd_codes_new,
    on_or_before = "index_date",
    returning = "binary_flag",
  ),  
  ## HIV/AIDs
  hiv_aids_nhsd_snomed = patients.with_these_clinical_events(
    hiv_aids_nhsd_snomed_codes,
    on_or_before = "index_date",
    returning = "binary_flag",
  ),
  
  hiv_aids_nhsd_icd10 = patients.admitted_to_hospital(
    returning = "binary_flag",
    on_or_before = "index_date",
    with_these_diagnoses = hiv_aids_nhsd_icd10_codes,
  ),
  
  hiv_aids_nhsd = patients.minimum_of("hiv_aids_nhsd_snomed", "hiv_aids_nhsd_icd10"),
  
  ## Solid organ transplant
  solid_organ_transplant_nhsd_snomed = patients.with_these_clinical_events(
    solid_organ_transplant_nhsd_snomed_codes,
    on_or_before = "index_date",
    returning = "date",
    date_format = "YYYY-MM-DD",
    find_last_match_in_period = True,
  ),
  solid_organ_nhsd_snomed_new = patients.with_these_clinical_events(
    solid_organ_transplant_nhsd_snomed_codes_new,
    on_or_before = "index_date",
    returning = "date",
    date_format = "YYYY-MM-DD",
    find_last_match_in_period = True,
  ),  
  solid_organ_transplant_nhsd_opcs4 = patients.admitted_to_hospital(
    returning = "date_admitted",
    on_or_before = "index_date",
    with_these_procedures = solid_organ_transplant_nhsd_opcs4_codes,
    date_format = "YYYY-MM-DD",
    find_last_match_in_period = True,
    return_expectations = {
      "date": {"earliest": "2020-02-01"},
      "rate": "exponential_increase",
      "incidence": 0.01,
    },
  ),
  
    transplant_all_y_codes_opcs4 = patients.admitted_to_hospital(
    returning = "date_admitted",
    with_these_procedures = replacement_of_organ_transplant_nhsd_opcs4_codes,
    on_or_before = "index_date",
    date_format = "YYYY-MM-DD",
    find_last_match_in_period = True,
    return_expectations = {
        "date": {"earliest": "2020-02-01"},
        "rate": "exponential_increase",
        "incidence": 0.01,
    },
    ),    
  
  transplant_thymus_opcs4 = patients.admitted_to_hospital(
    returning = "date_admitted",
    with_these_procedures = thymus_gland_transplant_nhsd_opcs4_codes,
    between = ["transplant_all_y_codes_opcs4","transplant_all_y_codes_opcs4"],
    date_format = "YYYY-MM-DD",
    find_last_match_in_period = True,
    return_expectations = {
      "date": {"earliest": "2020-02-01"},
      "rate": "exponential_increase",
      "incidence": 0.01,
    },
  ),
  
  transplant_conjunctiva_y_code_opcs4 = patients.admitted_to_hospital(
    returning = "date_admitted",
    with_these_procedures = conjunctiva_y_codes_transplant_nhsd_opcs4_codes,
    on_or_before = "index_date",
    date_format = "YYYY-MM-DD",
    find_last_match_in_period = True,
    return_expectations = {
      "date": {"earliest": "2020-02-01"},
      "rate": "exponential_increase",
      "incidence": 0.01,
    },
  ),
  
  transplant_conjunctiva_opcs4 = patients.admitted_to_hospital(
    returning = "date_admitted",
    with_these_procedures = conjunctiva_transplant_nhsd_opcs4_codes,
    between = ["transplant_conjunctiva_y_code_opcs4","transplant_conjunctiva_y_code_opcs4"],
    date_format = "YYYY-MM-DD",
    find_last_match_in_period = True,
    return_expectations = {
      "date": {"earliest": "2020-02-01"},
      "rate": "exponential_increase",
      "incidence": 0.01,
    },
  ),
  
  transplant_stomach_opcs4 = patients.admitted_to_hospital(
    returning = "date_admitted",
    with_these_procedures = stomach_transplant_nhsd_opcs4_codes,
    between = ["transplant_all_y_codes_opcs4","transplant_all_y_codes_opcs4"],
    date_format = "YYYY-MM-DD",
    find_last_match_in_period = True,
    return_expectations = {
      "date": {"earliest": "2020-02-01"},
      "rate": "exponential_increase",
      "incidence": 0.01,
    },
  ),
  
  transplant_ileum_1_Y_codes_opcs4 = patients.admitted_to_hospital(
    returning = "date_admitted",
    with_these_procedures = ileum_1_y_codes_transplant_nhsd_opcs4_codes,
    on_or_before = "index_date",
    date_format = "YYYY-MM-DD",
    find_last_match_in_period = True,
    return_expectations = {
      "date": {"earliest": "2020-02-01"},
      "rate": "exponential_increase",
      "incidence": 0.01,
    },
  ),
  
  transplant_ileum_2_Y_codes_opcs4 = patients.admitted_to_hospital(
    returning = "date_admitted",
    with_these_procedures = ileum_2_y_codes_transplant_nhsd_opcs4_codes,
    on_or_before = "index_date",
    date_format = "YYYY-MM-DD",
    find_last_match_in_period = True,
    return_expectations = {
      "date": {"earliest": "2020-02-01"},
      "rate": "exponential_increase",
      "incidence": 0.01,
    },
  ),
  
  transplant_ileum_1_opcs4 = patients.admitted_to_hospital(
    returning = "date_admitted",
    with_these_procedures = ileum_1_transplant_nhsd_opcs4_codes,
    between = ["transplant_ileum_1_Y_codes_opcs4","transplant_ileum_1_Y_codes_opcs4"],
    date_format = "YYYY-MM-DD",
    find_last_match_in_period = True,
    return_expectations = {
      "date": {"earliest": "2020-02-01"},
      "rate": "exponential_increase",
      "incidence": 0.01,
    },
  ),
  
  transplant_ileum_2_opcs4 = patients.admitted_to_hospital(
    returning = "date_admitted",
    with_these_procedures = ileum_2_transplant_nhsd_opcs4_codes,
    between = ["transplant_ileum_2_Y_codes_opcs4","transplant_ileum_2_Y_codes_opcs4"],
    date_format = "YYYY-MM-DD",
    find_first_match_in_period = True,
    return_expectations = {
      "date": {"earliest": "2020-02-01"},
      "rate": "exponential_increase",
      "incidence": 0.01,
    },
  ),
  
  solid_organ_transplant_nhsd = patients.minimum_of("solid_organ_transplant_nhsd_snomed", "solid_organ_transplant_nhsd_opcs4",
                                                    "transplant_thymus_opcs4", "transplant_conjunctiva_opcs4", "transplant_stomach_opcs4",
                                                    "transplant_ileum_1_opcs4","transplant_ileum_2_opcs4"), 
  solid_organ_transplant_nhsd_new = patients.minimum_of("solid_organ_nhsd_snomed_new", "solid_organ_transplant_nhsd_opcs4",
                                                    "transplant_thymus_opcs4", "transplant_conjunctiva_opcs4", "transplant_stomach_opcs4",
                                                    "transplant_ileum_1_opcs4","transplant_ileum_2_opcs4"), 
  ## Rare neurological conditions
  
  ### Multiple sclerosis
  multiple_sclerosis_nhsd_snomed = patients.with_these_clinical_events(
    multiple_sclerosis_nhsd_snomed_codes,
    on_or_before = "index_date",
    returning = "binary_flag",
  ),
  
  multiple_sclerosis_nhsd_icd10 = patients.admitted_to_hospital(
    returning = "binary_flag",
    on_or_before = "index_date",
    with_these_diagnoses = multiple_sclerosis_nhsd_icd10_codes,
  ),
  
  multiple_sclerosis_nhsd = patients.maximum_of("multiple_sclerosis_nhsd_snomed", "multiple_sclerosis_nhsd_icd10"), 
  
  ### Motor neurone disease
  motor_neurone_disease_nhsd_snomed = patients.with_these_clinical_events(
    motor_neurone_disease_nhsd_snomed_codes,
    on_or_before = "index_date",
    returning = "binary_flag",
  ),
  
  motor_neurone_disease_nhsd_icd10 = patients.admitted_to_hospital(
    returning = "binary_flag",
    on_or_before = "index_date",
    with_these_diagnoses = motor_neurone_disease_nhsd_icd10_codes,
  ),
  
  motor_neurone_disease_nhsd = patients.maximum_of("motor_neurone_disease_nhsd_snomed", "motor_neurone_disease_nhsd_icd10"),
  
  ### Myasthenia gravis
  myasthenia_gravis_nhsd_snomed = patients.with_these_clinical_events(
    myasthenia_gravis_nhsd_snomed_codes,
    on_or_before = "index_date",
    returning = "binary_flag",
  ),
  
  myasthenia_gravis_nhsd_icd10 = patients.admitted_to_hospital(
    returning = "binary_flag",
    on_or_before = "index_date",
    with_these_diagnoses = myasthenia_gravis_nhsd_icd10_codes,
  ),
  
  myasthenia_gravis_nhsd = patients.maximum_of("myasthenia_gravis_nhsd_snomed", "myasthenia_gravis_nhsd_icd10"),
  
  ### Huntington’s disease
  huntingtons_disease_nhsd_snomed = patients.with_these_clinical_events(
    huntingtons_disease_nhsd_snomed_codes,
    on_or_before = "index_date",
    returning = "binary_flag",
  ),
  
  huntingtons_disease_nhsd_icd10 = patients.admitted_to_hospital(
    returning = "binary_flag",
    on_or_before = "index_date",
    with_these_diagnoses = huntingtons_disease_nhsd_icd10_codes,
  ),
  
  huntingtons_disease_nhsd = patients.maximum_of("huntingtons_disease_nhsd_snomed", "huntingtons_disease_nhsd_icd10"),
    
    #OUTCOMES
    hosp_covid_primary=patients.admitted_to_hospital(
        returning = "date_admitted",
        with_these_primary_diagnoses = covid_identification,
        with_patient_classification = ["1"], # ordinary admissions only - exclude day cases and regular attenders
        # see https://docs.opensafely.org/study-def-variables/#sus for more info
        # with_admission_method=["21", "22", "23", "24", "25", "2A", "2B", "2C", "2D", "28"], # emergency admissions only to exclude incidental COVID
        on_or_after="2020-03-01",
        find_first_match_in_period = True,
        date_format = "YYYY-MM-DD",
        return_expectations = {
        "date": {"earliest": "2020-03-01"},
        "rate": "uniform",
        "incidence": 0.1
        },
    ),
    hosp_covid_any=patients.admitted_to_hospital(
        returning = "date_admitted",
        with_these_diagnoses = covid_identification,
        with_patient_classification = ["1"], # ordinary admissions only - exclude day cases and regular attenders
        # see https://docs.opensafely.org/study-def-variables/#sus for more info
        # with_admission_method=["21", "22", "23", "24", "25", "2A", "2B", "2C", "2D", "28"], # emergency admissions only to exclude incidental COVID
        on_or_after="2020-03-01",
        find_first_match_in_period = True,
        date_format = "YYYY-MM-DD",
        return_expectations = {
        "date": {"earliest": "2020-03-01"},
        "rate": "uniform",
        "incidence": 0.1
        },
    ),
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