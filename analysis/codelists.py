from cohortextractor import codelist_from_csv, codelist

# Primary biliary cirrhosis
pbc_codes = codelist_from_csv(
    "codelists/user-ruthcostello-primary_biliary_cirrhosis.csv",
    system="snomed",
    column="code",
)

psc_codes = codelist_from_csv(
    "codelists/user-ruthcostello-primary-sclerosing-cholangitis.csv",
    system = "snomed",
    column =  "code",
)
udca_codes = codelist_from_csv(
    "codelists/opensafely-ursodeoxycholic_acid.csv",
    system = "snomed",
    column = "dmd_id",
)

# OUTCOME CODELISTS
covid_identification = codelist_from_csv(
    "codelists/opensafely-covid-identification.csv",
    system="icd10",
    column="icd10_code",
)

# Ethnicity
ethnicity_codes = codelist_from_csv(
    "codelists/opensafely-ethnicity-snomed-0removed.csv",
    system="snomed",
    column="snomedcode",
    category_column="Grouping_6",)

clear_smoking_codes = codelist_from_csv(
    "codelists/opensafely-smoking-clear.csv",
    system="ctv3",
    column="CTV3Code",
    category_column="Category",
)
unclear_smoking_codes = codelist_from_csv(
    "codelists/opensafely-smoking-unclear.csv",
    system="ctv3",
    column="CTV3Code",
    category_column="Category",
)