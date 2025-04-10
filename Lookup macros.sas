*Lookup macros;
%macro label_lookup(key);
%local key;
    %if %eval(&key = ALAT) %then ALT (U/L);
    %else %if %eval(&key = ALB) %then Albumin (g/L);
    %else %if %eval(&key = ALP) %then ALP (U/L);
    %else %if %eval(&key = APTT) %then aPTT (s);
    %else %if %eval(&key = ASAT) %then AST (U/L);
    %else %if %eval(&key = BASOF) %then Basophiles (×10^9/L);
    %else %if %eval(&key = BE) %then Base Excess (mmol/L);
    %else %if %eval(&key = BILI) %then Bilirubin (µmol/L);
    %else %if %eval(&key = BILI_K) %then Conjugated bilirubin (µmol/L);
    %else %if %eval(&key = BLAST) %then Blast cells (×10^9/L);
    %else %if %eval(&key = CA) %then Calcium (mmol/L);
    %else %if %eval(&key = CA_F) %then Free Calcium (mmol/L);
    %else %if %eval(&key = CL) %then Chloride (mmol/L);
    %else %if %eval(&key = CO2) %then Carbon Dioxide (kPa);
    %else %if %eval(&key = COHB) %then CO-Hb (%);
    %else %if %eval(&key = CRP) %then CRP (mg/L);
    %else %if %eval(&key = EGFR) %then eGFR (mL/min/1.73 m²);
    %else %if %eval(&key = EOSINO) %then Eosinophile count (×10^9/L);
    %else %if %eval(&key = ERYTRO) %then Erythrocyte count (×10^9/L);
    %else %if %eval(&key = ERYTROBL) %then Erythroblasts (×10^9/L);
    %else %if %eval(&key = FE) %then Iron (µmol/L);
    %else %if %eval(&key = FERRITIN) %then Ferritin (µg/L);
    %else %if %eval(&key = FIB) %then Fibrinogen (g/L);
    %else %if %eval(&key = GLUKOS) %then Glucose (mmol/L);
    %else %if %eval(&key = HAPTO) %then Haptoglobin (g/L);
    %else %if %eval(&key = HB) %then Hemoglobin (g/L);
    %else %if %eval(&key = HBA1C) %then HbA1c (mmol/L);
    %else %if %eval(&key = EVF) %then Hematocrit;
    %else %if %eval(&key = INR) %then INR;
    %else %if %eval(&key = K) %then Potassium (mmol/L);
    %else %if %eval(&key = KREA) %then Creatinine (µmol/L);
    %else %if %eval(&key = LAKTAT) %then Lactate (mmol/L);
    %else %if %eval(&key = LD) %then Lactate dehydrogenase (U/L);
    %else %if %eval(&key = LPK) %then Leukocyte count (×10^9/L);
    %else %if %eval(&key = LYMF) %then Lymphocyte count (×10^9/L);
    %else %if %eval(&key = MCH) %then MCH (pg);
    %else %if %eval(&key = MCHC) %then MCHC (g/L);
    %else %if %eval(&key = MCV) %then MCV (fL);
    %else %if %eval(&key = META) %then Metamyelocyte count (×10^9/L);
    %else %if %eval(&key = METHB) %then Methemoglobin (%);
    %else %if %eval(&key = MONO) %then Monocyte count (×10^9/L);
    %else %if %eval(&key = MYELO) %then Myelocyte count (×10^9/L);
    %else %if %eval(&key = NA) %then Sodium (mmol/L);
    %else %if %eval(&key = NEUTRO) %then Neutrophile count (×10^9/L);
    %else %if %eval(&key = NTPROBNP) %then NT-ProBNP (ng/L);
    %else %if %eval(&key = OSMO) %then Osmolality (mOsm/kg);
    %else %if %eval(&key = PCO2) %then PaCO2 (kPa);
    %else %if %eval(&key = PH) %then pH;
    %else %if %eval(&key = PO2) %then PaO2 (kPa);
    %else %if %eval(&key = RET) %then Reticulocyte count (×10^9/L);
    %else %if %eval(&key = SR) %then Sedimentation rate (mm/h);
    %else %if %eval(&key = STDBIK) %then Standard bicarbonate (mmol/L);
    %else %if %eval(&key = TPK) %then Platelet count (×10^9/L);
    %else %if %eval(&key = TRANSF) %then Transferrin (g/L);
    %else %if %eval(&key = TRI) %then Triglycerides (mmol/L);
    %else %if %eval(&key = TROP_I) %then Troponin I (ng/L);
    %else %if %eval(&key = TROP_T) %then Troponin T (ng/L);
    %else %if %eval(&key = GT) %then Glutamyl transferase (U/L);
    %else Unknown key;

%mend;

%macro label_lookup2(key);
%local key;
    %if %eval(&key = ALAT) %then ALT;
    %else %if %eval(&key = ALB) %then Albumin;
    %else %if %eval(&key = ALP) %then ALP;
    %else %if %eval(&key = APTT) %then aPTT;
    %else %if %eval(&key = ASAT) %then AST;
    %else %if %eval(&key = BASOF) %then Basophiles;
    %else %if %eval(&key = BE) %then Base Excess;
    %else %if %eval(&key = BILI) %then Bilirubin;
    %else %if %eval(&key = BILI_K) %then Conjugated bilirubin;
    %else %if %eval(&key = BLAST) %then Blast cells;
    %else %if %eval(&key = CA) %then Calcium;
    %else %if %eval(&key = CA_F) %then Free Calcium;
    %else %if %eval(&key = CL) %then Chloride;
    %else %if %eval(&key = CO2) %then Carbon Dioxide;
    %else %if %eval(&key = COHB) %then CO-Hb;
    %else %if %eval(&key = CRP) %then CRP;
    %else %if %eval(&key = EGFR) %then eGFR;
    %else %if %eval(&key = EOSINO) %then Eosinophile count;
    %else %if %eval(&key = ERYTRO) %then Erythrocyte count;
    %else %if %eval(&key = ERYTROBL) %then Erythroblasts;
    %else %if %eval(&key = FE) %then Iron;
    %else %if %eval(&key = FERRITIN) %then Ferritin;
    %else %if %eval(&key = FIB) %then Fibrinogen;
    %else %if %eval(&key = GLUKOS) %then Glucose;
    %else %if %eval(&key = HAPTO) %then Haptoglobin;
    %else %if %eval(&key = HB) %then Hemoglobin;
    %else %if %eval(&key = HBA1C) %then HbA1c;
    %else %if %eval(&key = EVF) %then Hematocrit;
    %else %if %eval(&key = INR) %then INR;
    %else %if %eval(&key = K) %then Potassium;
    %else %if %eval(&key = KREA) %then Creatinine;
    %else %if %eval(&key = LAKTAT) %then Lactate;
    %else %if %eval(&key = LD) %then Lactate dehydrogenase;
    %else %if %eval(&key = LPK) %then Leukocyte count;
    %else %if %eval(&key = LYMF) %then Lymphocyte count;
    %else %if %eval(&key = MCH) %then MCH;
    %else %if %eval(&key = MCHC) %then MCHC;
    %else %if %eval(&key = MCV) %then MCV;
    %else %if %eval(&key = META) %then Metamyelocyte count;
    %else %if %eval(&key = METHB) %then Methemoglobin;
    %else %if %eval(&key = MONO) %then Monocyte count;
    %else %if %eval(&key = MYELO) %then Myelocyte count;
    %else %if %eval(&key = NA) %then Sodium;
    %else %if %eval(&key = NEUTRO) %then Neutrophile count;
    %else %if %eval(&key = NTPROBNP) %then NT-ProBNP;
    %else %if %eval(&key = OSMO) %then Osmolality;
    %else %if %eval(&key = PCO2) %then PaCO2;
    %else %if %eval(&key = PH) %then pH;
    %else %if %eval(&key = PO2) %then PaO2;
    %else %if %eval(&key = RET) %then Reticulocyte count;
    %else %if %eval(&key = SR) %then Sedimentation rate;
    %else %if %eval(&key = STDBIK) %then Standard bicarbonate;
    %else %if %eval(&key = TPK) %then Platelet count;
    %else %if %eval(&key = TRANSF) %then Transferrin;
    %else %if %eval(&key = TRI) %then Triglycerides;
    %else %if %eval(&key = TROP_I) %then Troponin I;
    %else %if %eval(&key = TROP_T) %then Troponin T;
    %else %if %eval(&key = GT) %then Glutamyl transferase;
    %else Unknown key;

%mend;
%macro predictor_lookup(key);
%local key;
    %if %eval(&key = donorparity) %then Donor parity;
    %else %if %eval(&key = idbloodgroupcat) %then ABO identical transfusion;
    %else %if %eval(&key = meandonationtime) %then Time of donation;
    %else %if %eval(&key = meandonorage) %then Donor age (years);
    %else %if %eval(&key = meandonorhb) %then Donor Hb (g/L);
    %else %if %eval(&key = meandonorsex) %then Donor sex;
    %else %if %eval(&key = meanstoragetime) %then Storage time (days);
    %else %if %eval(&key = meanweekday) %then Weekday of donation;
    %else %if %eval(&key = numdoncat) %then Donors prior number of donations;
    %else %if %eval(&key = timesincecat) %then Time since donors previous donation (days);
    %else %if %eval(&key = foreigndonor) %then Donor born outside of Sweden;
    %else Unknown key;
%mend;

%macro predictor_lookup2(key);
%local key;
    %if %eval(&key = donorparity) %then Donor parity;
    %else %if %eval(&key = idbloodgroupcat) %then ABO identical transfusion;
    %else %if %eval(&key = meandonationtime) %then Time of donation;
    %else %if %eval(&key = meandonorage) %then Age of Donor ;
    %else %if %eval(&key = meandonorhb) %then Donor Hb;
    %else %if %eval(&key = meandonorsex) %then Donor sex;
    %else %if %eval(&key = meanstoragetime) %then Storage time ;
    %else %if %eval(&key = meanweekday) %then Weekday of donation;
    %else %if %eval(&key = numdoncat) %then Donors prior number of donations;
    %else %if %eval(&key = timesincecat) %then Time since donors previous donation;
    %else %if %eval(&key = foreigndonor) %then Donor born outside of Sweden;
    %else Unknown key;
%mend;
%macro lookuparrays;
    /* Define arrays for labels */
    array labels_keys[58] $10. _temporary_ ('ALAT', 'ALB', 'ALP', 'APTT', 'ASAT', 'BASOF', 'BE', 'BILI', 'BILI_K', 'BLAST', 'CA', 'CA_F', 'CL', 'CO2', 'COHB', 'CRP', 'EGFR', 'EOSINO', 'ERYTRO', 'ERYTROBL', 'FE', 'FERRITIN', 'FIB', 'GLUKOS', 'HAPTO', 'HB', 'HBA1C', 'EVF', 'INR', 'K', 'KREA', 'LAKTAT', 'LD', 'LPK', 'LYMF', 'MCH', 'MCHC', 'MCV', 'META', 'METHB', 'MONO', 'MYELO', 'NA', 'NEUTRO', 'NTPROBNP', 'OSMO', 'PCO2', 'PH', 'PO2', 'RET', 'SR', 'STDBIK', 'TPK', 'TRANSF', 'TRI', 'TROP_I', 'TROP_T', 'GT') ;
    
    array labels_values[58] $50. _temporary_('ALT', 'Albumin', 'ALP', 'aPTT', 'AST', 'Basophiles', 'Base Excess', 'Bilirubin', 'Conjugated bilirubin', 'Blast cells', 'Calcium', 'Free Calcium', 'Chloride', 'Carbon Dioxide', 'CO-Hb', 'CRP', 'eGFR', 'Eosinophile count', 'Erythrocyte count', 'Erythroblasts', 'Iron', 'Ferritin', 'Fibrinogen', 'Glucose', 'Haptoglobin', 'Hemoglobin', 'HbA1c', 'Hematocrit', 'INR', 'Potassium', 'Creatinine', 'Lactate', 'Lactate dehydrogenase', 'Leukocyte count', 'Lymphocyte count', 'Mean corpuscular hemoglobin', 'Mean corpuscular hemoglobin concentration', 'Mean corpuscular volume', 'Metamyelocyte count', 'Methemoglobin', 'Monocyte count', 'Myelocyte count', 'Sodium', 'Neutrophile count', 'NT-ProBNP', 'Osmolality', 'PaCO2', 'pH', 'PaO2', 'Reticulocyte count', 'Sedimentation rate', 'Standard bicarbonate', 'Platelet count', 'Transferrin', 'Triglycerides', 'Troponin I', 'Troponin T', 'Glutamyl transferase');

    /* Define arrays for predictors */
    array predictors_keys[11] $18. _temporary_ ('donorparity', 'idbloodgroupcat', 'meandonationtime', 'meandonorage', 'meandonorhb', 'meandonorsex', 'meanstoragetime', 'meanweekday', 'numdoncat', 'timesincecat', 'foreigndonor');
    
    array predictors_values[11] $50. _temporary_ ('Donor parity', 'ABO identical transfusion', 'Time of donation', 'Age of Donor', 'Donor Hb', 'Donor sex', 'Storage time', 'Weekday of donation', 'Donors prior number of donations', 'Time since donors previous donation', 'Donor born outside of Sweden');
%mend lookuparrays;

data labelcategoryhash;
length label $15 category $ 50;
    input label category ;
	category=tranwrd(category,"_"," ");
   datalines;
HB      A._Basic_hematology
TPK     A._Basic_hematology
LPK     A._Basic_hematology
MCV     A._Basic_hematology
EVF     A._Basic_hematology
MCH     A._Basic_hematology
MCHC    A._Basic_hematology
ERYTRO  B._Special_hematology
LYMF    B._Special_hematology
META   B._Special_hematology
MYELO   B._Special_hematology
MONO    B._Special_hematology
NEUTRO  B._Special_hematology
EOSINO  B._Special_hematology
ERYTROBL B._Special_hematology
BLASTS  B._Special_hematology
BASOF   B._Special_hematology
RET     C._Hemolysis
HAPTO   C._Hemolysis
BILI    C._Hemolysis
LD      C._Hemolysis
ALAT    D._Liver_tests
ASAT    D._Liver_tests
ALP     D._Liver_tests
GT      D._Liver_tests
ALB     D._Liver_tests
BILI_K  D._Liver_tests
K       E._Electrolytes
NA      E._Electrolytes
CA      E._Electrolytes
CA_F    E._Electrolytes
CL      E._Electrolytes
OSMO    E._Electrolytes
KREA    F._Kidney_function
EGFR    F._Kidney_function
STDBIK  F._Kidney_function
BE      G._Blood_gases
CO2     G._Blood_gases
PCO2    G._Blood_gases
PO2     G._Blood_gases
PH      G._Blood_gases
COHB    G._Blood_gases
LAKTAT  G._Blood_gases
METHB   G._Blood_gases
CRP     H._Inflammation
SR      H._Inflammation
FE      I._Iron_status
FERRITIN I._Iron_status
TRANSF  I._Iron_status
TROP_I  J._Cardiac_markers
TROP_T  J._Cardiac_markers
NTPROBNP J._Cardiac_markers
INR     K._Coagulation
APTT    K._Coagulation
FIB     K._Coagulation
;
run;
