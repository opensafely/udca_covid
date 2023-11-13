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

budesonide_codes = codelist_from_csv(
    "codelists/user-ruthcostello-budesonide-dmd.csv",
    system="snomed",
    column="dmd_id",
)

fenofibrate_codes = codelist_from_csv(
    "codelists/user-ruthcostello-fenofibrates-dmd.csv",
    system="snomed",
    column="dmd_id",
)

gc_codes=codelist_from_csv(
    "codelists/opensafely-asthma-oral-prednisolone-medication.csv",
    system="snomed",
    column="snomed_id",
)

severe_disease_codes_snomed=codelist_from_csv(
    "codelists/opensafely-condition-advanced-decompensated-cirrhosis-of-the-liver.csv",
    system="snomed",
    column="code",
)

severe_disease_codes_icd=codelist_from_csv(
    "codelists/opensafely-condition-advanced-decompensated-cirrhosis-of-the-liver-and-associated-conditions-icd-10.csv",
    system="icd10",
    column="code",
)

liver_transplant_snomed_codes=codelist_from_csv(
  "codelists/user-ruthcostello-liver-transplant.csv",
  system="snomed",
  column="code",
)

liver_transplant_opcs_codes=codelist_from_csv(
  "codelists/user-ruthcostello-liver-transplant-opcs4.csv",
  system="opcs4",
  column="code",
)

### Learning disability
learning_disability_snomed_codes = codelist_from_csv(
  "codelists/nhsd-primary-care-domain-refsets-ld_cod.csv",
  system = "snomed",
  column = "code",
)

### Sickle cell disease
sickle_cell_disease_nhsd_snomed_codes = codelist_from_csv(
  "codelists/nhsd-sickle-spl-atriskv4-snomed-ct.csv",
  system = "snomed",
  column = "code",
)

sickle_cell_disease_nhsd_icd10_codes = codelist_from_csv(
  "codelists/nhsd-sickle-spl-hes-icd-10.csv",
  system = "icd10",
  column = "code",
)

### Solid cancer
non_haematological_cancer_opensafely_snomed_codes = codelist_from_csv(
  "codelists/opensafely-cancer-excluding-lung-and-haematological-snomed.csv",
  system = "snomed",
  column = "id",
)
non_haematological_cancer_opensafely_snomed_codes_new = codelist_from_csv(
  "codelists/user-bangzheng-cancer-excluding-lung-and-haematological-snomed-new.csv",
  system = "snomed",
  column = "code",
)
lung_cancer_opensafely_snomed_codes = codelist_from_csv(
  "codelists/opensafely-lung-cancer-snomed.csv", 
  system = "snomed", 
  column = "id"
)

chemotherapy_radiotherapy_opensafely_snomed_codes = codelist_from_csv(
  "codelists/opensafely-chemotherapy-or-radiotherapy-snomed.csv", 
  system = "snomed", 
  column = "id"
)

### Patients with a haematological diseases
haematopoietic_stem_cell_transplant_nhsd_snomed_codes = codelist_from_csv(
  "codelists/nhsd-haematopoietic-stem-cell-transplant-snomed.csv", 
  system = "snomed", 
  column = "code"
)

haematopoietic_stem_cell_transplant_nhsd_icd10_codes = codelist_from_csv(
  "codelists/nhsd-haematopoietic-stem-cell-transplant-icd-10.csv", 
  system = "icd10", 
  column = "code"
)

haematopoietic_stem_cell_transplant_nhsd_opcs4_codes = codelist_from_csv(
  "codelists/nhsd-haematopoietic-stem-cell-transplant-opcs4.csv", 
  system = "opcs4", 
  column = "code"
)

haematological_malignancies_nhsd_snomed_codes = codelist_from_csv(
  "codelists/nhsd-haematological-malignancies-snomed.csv",
  system = "snomed",
  column = "code"
)

haematological_malignancies_nhsd_icd10_codes = codelist_from_csv(
  "codelists/nhsd-haematological-malignancies-icd-10.csv", 
  system = "icd10", 
  column = "code"
)

### Patients with renal disease

#### CKD stage 5
ckd_stage_5_nhsd_snomed_codes = codelist_from_csv(
  "codelists/nhsd-ckd-stage-5-snomed-ct.csv", 
  system = "snomed", 
  column = "code"
)

ckd_stage_5_nhsd_icd10_codes = codelist_from_csv(
  "codelists/nhsd-ckd-stage-5-icd-10.csv", 
  system = "icd10", 
  column = "code"
)

### Immune-mediated inflammatory disorders (IMID)
immunosuppresant_drugs_dmd_codes = codelist_from_csv(
  "codelists/nhsd-immunosuppresant-drugs-pra-dmd.csv", 
  system = "snomed", 
  column = "code"
)

immunosuppresant_drugs_snomed_codes = codelist_from_csv(
  "codelists/nhsd-immunosuppresant-drugs-pra-snomed.csv", 
  system = "snomed", 
  column = "code"
)

oral_steroid_drugs_dmd_codes = codelist_from_csv(
  "codelists/nhsd-oral-steroid-drugs-pra-dmd.csv",
  system = "snomed",
  column = "dmd_id",
)

oral_steroid_drugs_snomed_codes = codelist_from_csv(
  "codelists/nhsd-oral-steroid-drugs-snomed.csv", 
  system = "snomed", 
  column = "code"
)

### Primary immune deficiencies
immunosupression_nhsd_codes = codelist_from_csv(
  "codelists/nhsd-immunosupression-pcdcluster-snomed-ct.csv",
  system = "snomed",
  column = "code",
)
immunosupression_nhsd_codes_new = codelist_from_csv(
  "codelists/user-bangzheng-nhsd-immunosupression-pcdcluster-snomed-ct-new.csv",
  system = "snomed",
  column = "code",
)
## HIV/AIDs
hiv_aids_nhsd_snomed_codes = codelist_from_csv(
  "codelists/nhsd-hiv-aids-snomed.csv", 
  system = "snomed", 
  column = "code"
)

hiv_aids_nhsd_icd10_codes = codelist_from_csv(
  "codelists/nhsd-hiv-aids-icd10.csv", 
  system = "icd10", 
  column = "code"
)

## Solid organ transplant
solid_organ_transplant_codes = codelist_from_csv(
    "codelists/opensafely-solid-organ-transplantation-snomed.csv",
    system = "snomed",
    column = "id",
)

solid_organ_transplant_nhsd_snomed_codes = codelist_from_csv(
  "codelists/nhsd-transplant-spl-atriskv4-snomed-ct.csv",
  system = "snomed",
  column = "code",
)
solid_organ_transplant_nhsd_snomed_codes_new = codelist_from_csv(
  "codelists/user-bangzheng-nhsd-transplant-spl-atriskv4-snomed-ct-new.csv",
  system = "snomed",
  column = "code",
)
solid_organ_transplant_nhsd_opcs4_codes = codelist_from_csv(
  "codelists/nhsd-transplant-spl-hes-opcs4.csv", 
  system = "opcs4", 
  column = "code"
)

thymus_gland_transplant_nhsd_opcs4_codes = codelist_from_csv(
  "codelists/nhsd-transplant-thymus-gland-spl-hes-opcs4.csv", 
  system = "opcs4", 
  column = "code"
)

replacement_of_organ_transplant_nhsd_opcs4_codes = codelist_from_csv(
  "codelists/nhsd-transplant-replacement-of-organ-spl-hes-opcs4.csv", 
  system = "opcs4", 
  column = "code"
)

conjunctiva_transplant_nhsd_opcs4_codes = codelist_from_csv(
  "codelists/nhsd-transplant-conjunctiva-spl-hes-opcs4.csv", 
  system = "opcs4", 
  column = "code"
)

conjunctiva_y_codes_transplant_nhsd_opcs4_codes = codelist_from_csv(
  "codelists/nhsd-transplant-conjunctiva-y-codes-spl-hes-opcs4.csv", 
  system = "opcs4", 
  column = "code"
)

stomach_transplant_nhsd_opcs4_codes = codelist_from_csv(
  "codelists/nhsd-transplant-stomach-spl-hes-opcs4.csv", 
  system = "opcs4", 
  column = "code"
)

ileum_1_transplant_nhsd_opcs4_codes = codelist_from_csv(
  "codelists/nhsd-transplant-ileum_1-spl-hes-opcs4.csv", 
  system = "opcs4", 
  column = "code"
)

ileum_2_transplant_nhsd_opcs4_codes = codelist_from_csv(
  "codelists/nhsd-transplant-ileum_2-spl-hes-opcs4.csv", 
  system = "opcs4", 
  column = "code"
)

ileum_1_y_codes_transplant_nhsd_opcs4_codes = codelist_from_csv(
  "codelists/nhsd-transplant-ileum_1-y-codes-spl-hes-opcs4.csv", 
  system = "opcs4", 
  column = "code"
)

ileum_2_y_codes_transplant_nhsd_opcs4_codes = codelist_from_csv(
  "codelists/nhsd-transplant-ileum_2-y-codes-spl-hes-opcs4.csv", 
  system = "opcs4", 
  column = "code"
)

### Rare neurological conditions

#### Multiple sclerosis
multiple_sclerosis_nhsd_snomed_codes = codelist_from_csv(
  "codelists/nhsd-multiple-sclerosis-snomed-ct.csv",
  system = "snomed",
  column = "code",
)

multiple_sclerosis_nhsd_icd10_codes = codelist_from_csv(
  "codelists/nhsd-multiple-sclerosis.csv",
  system = "icd10",
  column = "code",
)

#### Motor neurone disease
motor_neurone_disease_nhsd_snomed_codes = codelist_from_csv(
  "codelists/nhsd-motor-neurone-disease-snomed-ct.csv",
  system = "snomed",
  column = "code",
)

motor_neurone_disease_nhsd_icd10_codes = codelist_from_csv(
  "codelists/nhsd-motor-neurone-disease-icd-10.csv",
  system = "icd10",
  column = "code",
)

#### Myasthenia gravis
myasthenia_gravis_nhsd_snomed_codes = codelist_from_csv(
  "codelists/nhsd-myasthenia-gravis-snomed-ct.csv",
  system = "snomed",
  column = "code",
)

myasthenia_gravis_nhsd_icd10_codes = codelist_from_csv(
  "codelists/nhsd-myasthenia-gravis.csv",
  system = "icd10",
  column = "code",
)

#### Huntington’s disease
huntingtons_disease_nhsd_snomed_codes = codelist_from_csv(
  "codelists/nhsd-huntingtons-snomed-ct.csv",
  system = "snomed",
  column = "code",
)

huntingtons_disease_nhsd_icd10_codes = codelist_from_csv(
  "codelists/nhsd-huntingtons.csv",
  system = "icd10",
  column = "code",
)  

liver_death_codes = codelist_from_csv(
  "codelists/user-ruthcostello-liver_chapter_plus.csv",
  system = "icd10",
  column = "code",
)

oca_hcd_codes = codelist_from_csv(
  "other_codelists/hcd-obeticholic-acid-drug-names.csv",
  system = "none",
  column = "olddrugname",
)

udca_hcd_codes = codelist_from_csv(
  "other_codelists/hcd-ursodeoxycholic-acid-drug-names.csv",
  system = "none",
  column = "olddrugname",
)