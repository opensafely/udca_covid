from cohortextractor import codelist_from_csv, codelist

# Primary biliary cirrhosis
pbc_codes = codelist_from_csv(
    "user-ruthcostello-primary-biliary-cirrhosis.csv",
    system="snomed",
    column="code",
)

udca_codes = codelist_from_csv(
    "opensafely-ursodeoxycholic_acid.csv",
    system = "snomed",
    column = "dmd_id",
)

# OUTCOME CODELISTS
covid_identification = codelist_from_csv(
    "codelists/opensafely-covid-identification.csv",
    system="icd10",
    column="icd10_code",
)
