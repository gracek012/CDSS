
--
--Patients ordered for and receiving subQ insulin inpatient (n=51,887 patients in 88,372 encounters)
SELECT jc_uid, pat_enc_csn_id_coded, order_med_id_coded, medication_id, med_description, ordering_mode, med_route from starr_datalake2018.order_med
	WHERE order_med_id_coded in 
  (SELECT order_med_id_coded FROM starr_datalake2018.mar --insulin given
	   WHERE order_med_id_coded IN (SELECT order_med_id_coded FROM `starr_datalake2018.order_med`
	     WHERE UPPER(med_description) LIKE '%INSULIN%'-- insulin ordered
     	AND (ordering_mode_c) = 2 -- inpatient
      AND med_route = 'Subcutaneous')) --and subQ
	ORDER BY jc_uid, med_description  ASC 


-- 
-- MAR insulin
SELECT jc_uid, pat_enc_csn_id_coded, order_med_id_coded, infusion_rate, sig, dose_unit_c, dose_unit, mar_action, route, route_c FROM `mining-clinical-decisions.starr_datalake2018.mar` 
-- SELECT  mar_action FROM `mining-clinical-decisions.starr_datalake2018.mar` 
	WHERE order_med_id_coded in 
  (SELECT order_med_id_coded FROM starr_datalake2018.order_med 
	     WHERE UPPER(med_description) LIKE '%INSULIN%'-- insulin ordered)
       AND (ordering_mode_c) = 2 -- inpatient
       AND med_route = 'Subcutaneous') --and subQ
   AND (mar_action) IN ('Bolus', 'Complete', 'Completed', 'Given', 'Push', 'Refused', 'Held', 'Stopped', 'Missed') 
   AND (mar_action) NOT IN ('Bag Removal', 'Canceled Entry', 'Due', 'Existing Bag', 'Infusion Restarted', 'Infusion Started', 'Infusion Stopped', 'New Bag', 'Patch Removal', 'Patient\'s Own Med', 'Patient/Family Admin', 'Paused', 'Pending', 'Rate Changed', 'Rate Verify', 'Pump%', 'See Anesthesia Record', 'Self Administered Med', 'See Override Pull')
   AND dose_unit_c = 5 -- "units", not an infusion (not units/hr)
--   AND (mar_action) IN ('Bolus', 'PUMP Bolus', 'Pump Check', 'Restarted', 'Stopped', 'Given')
   AND (mar_action) IN ('Completed', 'Given', 'Push', 'Refused', 'Held', 'Stopped', 'Missed')       
-- GROUP BY mar_action   
ORDER BY mar_action, jc_uid 


--
-- Evaluating if "sig" is the insulin dose given
SELECT sig, COUNT(sig) as number FROM `mining-clinical-decisions.starr_datalake2018.mar` 
	WHERE order_med_id_coded in 
  (SELECT order_med_id_coded FROM starr_datalake2018.order_med 
	     WHERE UPPER(med_description) LIKE '%INSULIN%'-- insulin ordered)
       AND (ordering_mode_c) = 2 -- inpatient
       AND med_route = 'Subcutaneous') --and subQ
   AND (mar_action) IN ('Bolus', 'Complete', 'Completed', 'Given', 'Push', 'Refused', 'Held', 'Stopped', 'Missed') 
   AND (mar_action) NOT IN ('Bag Removal', 'Canceled Entry', 'Due', 'Existing Bag', 'Infusion Restarted', 'Infusion Started', 'Infusion Stopped', 'New Bag', 'Patch Removal', 'Patient\'s Own Med', 'Patient/Family Admin', 'Paused', 'Pending', 'Rate Changed', 'Rate Verify', 'Pump%', 'See Anesthesia Record', 'Self Administered Med', 'See Override Pull')
   AND dose_unit_c = 5 -- "units", not an infusion (not units/hr)
--   AND (mar_action) IN ('Bolus', 'PUMP Bolus', 'Pump Check', 'Restarted', 'Stopped', 'Given')
   AND sig <> "0-10" 
   AND sig IS NOT NULL 
GROUP BY sig  
ORDER BY CAST(sig AS float64) --converts string to number


--
-- MAR insulin given, excluding pump dosing (assumed that partial units = pump)
SELECT jc_uid, pat_enc_csn_id_coded, order_med_id_coded, sig, dose_unit, mar_action, route FROM `mining-clinical-decisions.starr_datalake2018.mar` 
-- SELECT  infusion_rate  FROM `mining-clinical-decisions.starr_datalake2018.mar` 
-- SELECT sig, COUNT(sig) as number FROM `mining-clinical-decisions.starr_datalake2018.mar` 
	WHERE order_med_id_coded in 
  (SELECT order_med_id_coded FROM starr_datalake2018.order_med 
	     WHERE UPPER(med_description) LIKE '%INSULIN%'-- insulin ordered)
       AND (ordering_mode_c) = 2 -- inpatient
       AND med_route = 'Subcutaneous') --and subQ
     AND (mar_action) IN ('Bolus', 'Complete', 'Completed', 'Given', 'Push')
--   AND (mar_action) IN ('Bolus', 'Complete', 'Completed', 'Given', 'Push', 'Refused', 'Held', 'Stopped', 'Missed') 
   AND (mar_action) NOT IN ('Bag Removal', 'Canceled Entry', 'Due', 'Existing Bag', 'Infusion Restarted', 'Infusion Started', 'Infusion Stopped', 'New Bag', 'Patch Removal', 'Patient\'s Own Med', 'Patient/Family Admin', 'Paused', 'Pending', 'Rate Changed', 'Rate Verify', 'Pump%', 'See Anesthesia Record', 'Self Administered Med', 'See Override Pull','Refused', 'Held', 'Stopped', 'Missed')
   AND dose_unit_c = 5 -- "units", not an infusion (not units/hr)
--   AND (mar_action) IN ('Bolus', 'PUMP Bolus', 'Pump Check', 'Restarted', 'Stopped', 'Given')
   AND sig <> "0-10"
   AND sig IS NOT NULL 
   AND sig NOT LIKE "%.%" -- removes any partial unit injections (assumed to be pump)
   AND infusion_rate IS NULL -- infusion_rate assumed to signify pump pt
-- GROUP BY sig  
ORDER BY CAST(sig AS float64) --converts string to number


--
-- MAR insulin given joined to name of insulin 
SELECT mar.jc_uid, mar.pat_enc_csn_id_coded, mar.order_med_id_coded,  medord.med_description, mar.sig,  mar.dose_unit, mar.mar_action, mar.route FROM `mining-clinical-decisions.starr_datalake2018.mar` as mar 
  LEFT JOIN starr_datalake2018.order_med as medord on mar.order_med_id_coded=medord.order_med_id_coded 
	WHERE mar.order_med_id_coded in 
  (SELECT medord2.order_med_id_coded FROM starr_datalake2018.order_med as medord2
	     WHERE UPPER(medord2.med_description) LIKE '%INSULIN%'-- insulin ordered)
       AND (medord2.ordering_mode_c) = 2 -- inpatient
       AND UPPER(medord2.med_description) NOT LIKE '%PUMP%' --excludes pumps
       AND medord2.med_route = 'Subcutaneous') --and subQ
     AND (mar.mar_action) IN ('Bolus', 'Complete', 'Completed', 'Given', 'Push')
--   AND (mar_action) IN ('Bolus', 'Complete', 'Completed', 'Given', 'Push', 'Refused', 'Held', 'Stopped', 'Missed') 
   AND (mar.mar_action) NOT IN ('Bag Removal', 'Canceled Entry', 'Due', 'Existing Bag', 'Infusion Restarted', 'Infusion Started', 'Infusion Stopped', 'New Bag', 'Patch Removal', 'Patient\'s Own Med', 'Patient/Family Admin', 'Paused', 'Pending', 'Rate Changed', 'Rate Verify', 'Pump%', 'See Anesthesia Record', 'Self Administered Med', 'See Override Pull','Refused', 'Held', 'Stopped', 'Missed')
   AND mar.dose_unit_c = 5 -- "units", not an infusion (not units/hr)
--   AND (mar_action) IN ('Bolus', 'PUMP Bolus', 'Pump Check', 'Restarted', 'Stopped', 'Given')
   AND mar.sig <> "0-10"
   AND mar.sig IS NOT NULL 
   AND mar.sig NOT LIKE "%.%" -- removes any partial unit injections (assumed to be pump)
   AND mar.infusion_rate IS NULL -- infusion_rate assumed to signify pump pt
-- GROUP BY sig  
ORDER BY CAST(mar.sig AS float64) --converts string to number


--
-- MAR insulin given w/ name of insulin, excluding insulin cartridges and types ordered <10x
SELECT mar.jc_uid, mar.pat_enc_csn_id_coded, mar.order_med_id_coded,  medord.med_description, mar.sig,  mar.dose_unit, mar.mar_action, mar.route, mar.taken_time_jittered FROM `mining-clinical-decisions.starr_datalake2018.mar` as mar 
-- SELECT  medord.med_description, count(medord.med_description) as number FROM `mining-clinical-decisions.starr_datalake2018.mar` as mar 
  LEFT JOIN starr_datalake2018.order_med as medord on mar.order_med_id_coded=medord.order_med_id_coded 
	WHERE mar.order_med_id_coded in 
  (SELECT medord2.order_med_id_coded FROM starr_datalake2018.order_med as medord2
	     WHERE UPPER(medord2.med_description) LIKE '%INSULIN%'-- insulin ordered)
       AND (medord2.ordering_mode_c) = 2 -- inpatient
       AND UPPER(medord2.med_description) NOT LIKE '%PUMP%' --excludes pumps
       AND (medord2.med_description) NOT IN ("INSULIN NPH HUMAN RECOMB 100 UNIT/ML SC CRTG", "INSULIN LISPRO PROTAM-LISPRO 100 UNIT/ML (50-50) SC SUSP", "INSULIN GLARGINE 300 UNIT/ML (3 ML) SC INPN", "INSULIN NPH & REGULAR HUMAN 100 UNIT/ML (70-30) SC CRTG", "INSULIN NPH-REGULAR HUM S-SYN 100 UNIT/ML (70-30) SC CRTG", "INSULIN ASP PRT-INSULIN ASPART 100 UNIT/ML (70-30) SC SOLN", "INSULIN LISPRO 100 UNIT/ML SC INPH", "INSULIN NPH HUMAN SEMI-SYN 100 UNIT/ML SC CRTG", "INSULIN ASPART PROTAMINE-ASPART (70/30) 100 UNIT/ML SUBCUTANEOUS PEN", "INSULIN LISPRO PROTAM-LISPRO 100 UNIT/ML (75-25) SC SUSP", "INSULIN GLULISINE 100 UNIT/ML SC CRTG", "INSULIN DEGLUDEC-LIRAGLUTIDE 100 UNIT-3.6 MG /ML (3 ML) SC INPN", "INSULIN LISPRO PROTAM & LISPRO 100 UNIT/ML (75-25) SC SUSP", "INSULIN REGULAR HUM U-500 CONC 500 UNIT/ML SC SOLN", "INSULIN LISPRO 100 UNIT/ML SC CRTG", "INSULIN ASPART 100 UNIT/ML SC CRTG") -- removes anything ordered <10 times
       AND medord2.med_description NOT LIKE "%CRTG%" -- excludes anything ordered as a cartridge to remove pumps
       AND medord2.med_route = 'Subcutaneous') --and subQ
     AND (mar.mar_action) IN ('Bolus', 'Complete', 'Completed', 'Given', 'Push') --medication actually given
   AND (mar.mar_action) NOT IN ('Bag Removal', 'Canceled Entry', 'Due', 'Existing Bag', 'Infusion Restarted', 'Infusion Started', 'Infusion Stopped', 'New Bag', 'Patch Removal', 'Patient\'s Own Med', 'Patient/Family Admin', 'Paused', 'Pending', 'Rate Changed', 'Rate Verify', 'Pump%', 'See Anesthesia Record', 'Self Administered Med', 'See Override Pull','Refused', 'Held', 'Stopped', 'Missed')
   AND mar.dose_unit_c = 5 -- "units", not an infusion (not units/hr)
   AND mar.sig <> "0-10"
   AND mar.sig IS NOT NULL 
   AND mar.sig NOT LIKE "%.%" -- removes any partial unit injections (assumed to be pump)
   AND mar.infusion_rate IS NULL -- infusion_rate assumed to signify pump pt
ORDER BY CAST(mar.sig AS float64) --converts string to number
-- ORDER BY mar.taken_time_jittered 


-- 
-- NERO version of MAR insulin given w/ name of insulin, excluding insulin cartridges and types ordered <10x
SELECT mar.jc_uid, mar.pat_enc_csn_id_coded, mar.order_med_id_coded,  medord.med_description, mar.sig,  mar.dose_unit, mar.mar_action, mar.route, mar.taken_time_jittered FROM `som-nero-phi-jonc101.starr_datalake2018.mar` as mar 
-- SELECT  medord.med_description, count(medord.med_description) as number FROM `mining-clinical-decisions.starr_datalake2018.mar` as mar 
  LEFT JOIN `som-nero-phi-jonc101.starr_datalake2018.order_med` as medord on mar.order_med_id_coded=medord.order_med_id_coded 
  WHERE mar.order_med_id_coded in 
  (SELECT medord2.order_med_id_coded FROM `som-nero-phi-jonc101.starr_datalake2018.order_med` as medord2
       WHERE UPPER(medord2.med_description) LIKE '%INSULIN%'-- insulin ordered)
       AND (medord2.ordering_mode_c) = 2 -- inpatient
       AND UPPER(medord2.med_description) NOT LIKE '%PUMP%' --excludes pumps
       AND (medord2.med_description) NOT IN ("INSULIN NPH HUMAN RECOMB 100 UNIT/ML SC CRTG", "INSULIN LISPRO PROTAM-LISPRO 100 UNIT/ML (50-50) SC SUSP", "INSULIN GLARGINE 300 UNIT/ML (3 ML) SC INPN", "INSULIN NPH & REGULAR HUMAN 100 UNIT/ML (70-30) SC CRTG", "INSULIN NPH-REGULAR HUM S-SYN 100 UNIT/ML (70-30) SC CRTG", "INSULIN ASP PRT-INSULIN ASPART 100 UNIT/ML (70-30) SC SOLN", "INSULIN LISPRO 100 UNIT/ML SC INPH", "INSULIN NPH HUMAN SEMI-SYN 100 UNIT/ML SC CRTG", "INSULIN ASPART PROTAMINE-ASPART (70/30) 100 UNIT/ML SUBCUTANEOUS PEN", "INSULIN LISPRO PROTAM-LISPRO 100 UNIT/ML (75-25) SC SUSP", "INSULIN GLULISINE 100 UNIT/ML SC CRTG", "INSULIN DEGLUDEC-LIRAGLUTIDE 100 UNIT-3.6 MG /ML (3 ML) SC INPN", "INSULIN LISPRO PROTAM & LISPRO 100 UNIT/ML (75-25) SC SUSP", "INSULIN REGULAR HUM U-500 CONC 500 UNIT/ML SC SOLN", "INSULIN LISPRO 100 UNIT/ML SC CRTG", "INSULIN ASPART 100 UNIT/ML SC CRTG") -- removes anything ordered <10 times
       AND medord2.med_description NOT LIKE "%CRTG%" -- excludes anything ordered as a cartridge to remove pumps
       AND medord2.med_route = 'Subcutaneous') --and subQ
     AND (mar.mar_action) IN ('Bolus', 'Complete', 'Completed', 'Given', 'Push') --medication actually given
   AND (mar.mar_action) NOT IN ('Bag Removal', 'Canceled Entry', 'Due', 'Existing Bag', 'Infusion Restarted', 'Infusion Started', 'Infusion Stopped', 'New Bag', 'Patch Removal', 'Patient\'s Own Med', 'Patient/Family Admin', 'Paused', 'Pending', 'Rate Changed', 'Rate Verify', 'Pump%', 'See Anesthesia Record', 'Self Administered Med', 'See Override Pull','Refused', 'Held', 'Stopped', 'Missed')
   AND mar.dose_unit_c = 5 -- "units", not an infusion (not units/hr)
   AND mar.sig <> "0-10"
   AND mar.sig IS NOT NULL 
   AND mar.sig NOT LIKE "%.%" -- removes any partial unit injections (assumed to be pump)
   AND mar.infusion_rate IS NULL -- infusion_rate assumed to signify pump pt
ORDER BY CAST(mar.sig AS float64) --converts string to number
-- ORDER BY mar.taken_time_jittered 

-- 
-- Units subQ insulin given where creatinine <2 during the patient encounter
SELECT mar.jc_uid, mar.pat_enc_csn_id_coded, mar.sig as units, mar.mar_action, medord.med_description, mar.route, medord.medication_id, medord.sig, mar.taken_time_jittered as instructions FROM `som-nero-phi-jonc101.starr_datalake2018.mar` as mar 
  LEFT JOIN `som-nero-phi-jonc101.starr_datalake2018.order_med` as medord on mar.order_med_id_coded=medord.order_med_id_coded 
  WHERE mar.order_med_id_coded in 
  (SELECT medord2.order_med_id_coded FROM `som-nero-phi-jonc101.starr_datalake2018.order_med` as medord2
       WHERE UPPER(medord2.med_description) LIKE '%INSULIN%'-- insulin ordered)
       AND (medord2.ordering_mode_c) = 2 -- inpatient
       AND UPPER(medord2.med_description) NOT LIKE '%PUMP%' --excludes pumps
       AND (medord2.med_description) NOT IN ("INSULIN NPH HUMAN RECOMB 100 UNIT/ML SC CRTG", "INSULIN LISPRO PROTAM-LISPRO 100 UNIT/ML (50-50) SC SUSP", "INSULIN GLARGINE 300 UNIT/ML (3 ML) SC INPN", "INSULIN NPH & REGULAR HUMAN 100 UNIT/ML (70-30) SC CRTG", "INSULIN NPH-REGULAR HUM S-SYN 100 UNIT/ML (70-30) SC CRTG", "INSULIN ASP PRT-INSULIN ASPART 100 UNIT/ML (70-30) SC SOLN", "INSULIN LISPRO 100 UNIT/ML SC INPH", "INSULIN NPH HUMAN SEMI-SYN 100 UNIT/ML SC CRTG", "INSULIN ASPART PROTAMINE-ASPART (70/30) 100 UNIT/ML SUBCUTANEOUS PEN", "INSULIN LISPRO PROTAM-LISPRO 100 UNIT/ML (75-25) SC SUSP", "INSULIN GLULISINE 100 UNIT/ML SC CRTG", "INSULIN DEGLUDEC-LIRAGLUTIDE 100 UNIT-3.6 MG /ML (3 ML) SC INPN", "INSULIN LISPRO PROTAM & LISPRO 100 UNIT/ML (75-25) SC SUSP", "INSULIN REGULAR HUM U-500 CONC 500 UNIT/ML SC SOLN", "INSULIN LISPRO 100 UNIT/ML SC CRTG", "INSULIN ASPART 100 UNIT/ML SC CRTG") -- removes anything ordered <10 times
       AND medord2.med_description NOT LIKE "%CRTG%" -- excludes anything ordered as a cartridge to remove pumps
       AND medord2.med_route = 'Subcutaneous') --and subQ
     AND (mar.mar_action) IN ('Given') --medication actually given
   AND (mar.mar_action) NOT IN ('Bag Removal', 'Canceled Entry', 'Due', 'Existing Bag', 'Infusion Restarted', 'Infusion Started', 'Infusion Stopped', 'New Bag', 'Patch Removal', 'Patient\'s Own Med', 'Patient/Family Admin', 'Paused', 'Pending', 'Rate Changed', 'Rate Verify', 'Pump%', 'See Anesthesia Record', 'Self Administered Med', 'See Override Pull','Refused', 'Held', 'Stopped', 'Missed', 'Bolus', 'Complete', 'Completed', 'Push')
   AND mar.dose_unit_c = 5 -- "units", not an infusion (not units/hr)
   AND mar.sig <> "0-10"
   AND mar.sig IS NOT NULL 
   AND mar.sig NOT LIKE "%.%" -- removes any partial unit injections (assumed to be pump)
   AND mar.infusion_rate IS NULL -- infusion_rate assumed to signify pump pt
   AND mar.pat_enc_csn_id_coded NOT IN (SELECT lab.pat_enc_csn_id_coded FROM `som-nero-phi-jonc101.starr_datalake2018.lab_result` as lab -- excludes patient encounters with creatinine >2 
    WHERE (lab_name) LIKE "Creatinine, Ser/Plas" --most common creatinine order
    AND ord_num_value != 9999999
    AND taken_time_jittered IS NOT null
    AND ord_num_value > 2)

--
-- Units subQ insulin given (>0units) where creatinine <2 during the patient encounter
SELECT mar.jc_uid, mar.pat_enc_csn_id_coded, mar.sig as units, mar.mar_action, medord.med_description, mar.route, medord.medication_id, medord.sig, mar.taken_time_jittered as instructions FROM `som-nero-phi-jonc101.starr_datalake2018.mar` as mar 
  LEFT JOIN `som-nero-phi-jonc101.starr_datalake2018.order_med` as medord on mar.order_med_id_coded=medord.order_med_id_coded 
  WHERE mar.order_med_id_coded in 
  (SELECT medord2.order_med_id_coded FROM `som-nero-phi-jonc101.starr_datalake2018.order_med` as medord2
       WHERE UPPER(medord2.med_description) LIKE '%INSULIN%'-- insulin ordered)
       AND (medord2.ordering_mode_c) = 2 -- inpatient
       AND UPPER(medord2.med_description) NOT LIKE '%PUMP%' --excludes pumps
       AND (medord2.med_description) NOT IN ("INSULIN NPH HUMAN RECOMB 100 UNIT/ML SC CRTG", "INSULIN LISPRO PROTAM-LISPRO 100 UNIT/ML (50-50) SC SUSP", "INSULIN GLARGINE 300 UNIT/ML (3 ML) SC INPN", "INSULIN NPH & REGULAR HUMAN 100 UNIT/ML (70-30) SC CRTG", "INSULIN NPH-REGULAR HUM S-SYN 100 UNIT/ML (70-30) SC CRTG", "INSULIN ASP PRT-INSULIN ASPART 100 UNIT/ML (70-30) SC SOLN", "INSULIN LISPRO 100 UNIT/ML SC INPH", "INSULIN NPH HUMAN SEMI-SYN 100 UNIT/ML SC CRTG", "INSULIN ASPART PROTAMINE-ASPART (70/30) 100 UNIT/ML SUBCUTANEOUS PEN", "INSULIN LISPRO PROTAM-LISPRO 100 UNIT/ML (75-25) SC SUSP", "INSULIN GLULISINE 100 UNIT/ML SC CRTG", "INSULIN DEGLUDEC-LIRAGLUTIDE 100 UNIT-3.6 MG /ML (3 ML) SC INPN", "INSULIN LISPRO PROTAM & LISPRO 100 UNIT/ML (75-25) SC SUSP", "INSULIN REGULAR HUM U-500 CONC 500 UNIT/ML SC SOLN", "INSULIN LISPRO 100 UNIT/ML SC CRTG", "INSULIN ASPART 100 UNIT/ML SC CRTG") -- removes anything ordered <10 times
       AND medord2.med_description NOT LIKE "%CRTG%" -- excludes anything ordered as a cartridge to remove pumps
       AND medord2.med_route = 'Subcutaneous') --and subQ
     AND (mar.mar_action) IN ('Given') --medication actually given
   AND (mar.mar_action) NOT IN ('Bag Removal', 'Canceled Entry', 'Due', 'Existing Bag', 'Infusion Restarted', 'Infusion Started', 'Infusion Stopped', 'New Bag', 'Patch Removal', 'Patient\'s Own Med', 'Patient/Family Admin', 'Paused', 'Pending', 'Rate Changed', 'Rate Verify', 'Pump%', 'See Anesthesia Record', 'Self Administered Med', 'See Override Pull','Refused', 'Held', 'Stopped', 'Missed', 'Bolus', 'Complete', 'Completed', 'Push')
   AND mar.dose_unit_c = 5 -- "units", not an infusion (not units/hr)
   AND mar.sig <> "0-10"
   AND CAST(mar.sig AS float64) > 0
   AND mar.sig IS NOT NULL 
   AND mar.sig NOT LIKE "%.%" -- removes any partial unit injections (assumed to be pump)
   AND mar.infusion_rate IS NULL -- infusion_rate assumed to signify pump pt
   AND mar.pat_enc_csn_id_coded NOT IN (SELECT lab.pat_enc_csn_id_coded FROM `som-nero-phi-jonc101.starr_datalake2018.lab_result` as lab -- excludes patient encounters with creatinine >2 
    WHERE (lab_name) LIKE "Creatinine, Ser/Plas" --most common creatinine order
    AND ord_num_value != 9999999
    AND taken_time_jittered IS NOT null
    AND ord_num_value > 2)


-- 
-- Units subQ insulin given (>0units) where creatinine <2 during the patient encounter, excluding U500
SELECT mar.jc_uid, mar.pat_enc_csn_id_coded, mar.sig as units, mar.mar_action, medord.med_description, mar.route, medord.medication_id, medord.sig, mar.taken_time_jittered as instructions FROM `som-nero-phi-jonc101.starr_datalake2018.mar` as mar 
  LEFT JOIN `som-nero-phi-jonc101.starr_datalake2018.order_med` as medord on mar.order_med_id_coded=medord.order_med_id_coded 
  WHERE mar.order_med_id_coded in 
  (SELECT medord2.order_med_id_coded FROM `som-nero-phi-jonc101.starr_datalake2018.order_med` as medord2
       WHERE UPPER(medord2.med_description) LIKE '%INSULIN%'-- insulin ordered)
       AND (medord2.ordering_mode_c) = 2 -- inpatient
       AND UPPER(medord2.med_description) NOT LIKE '%PUMP%' --excludes pumps
       AND (medord2.med_description) NOT IN ("INSULIN NPH HUMAN RECOMB 100 UNIT/ML SC CRTG", "INSULIN LISPRO PROTAM-LISPRO 100 UNIT/ML (50-50) SC SUSP", "INSULIN GLARGINE 300 UNIT/ML (3 ML) SC INPN", "INSULIN NPH & REGULAR HUMAN 100 UNIT/ML (70-30) SC CRTG", "INSULIN NPH-REGULAR HUM S-SYN 100 UNIT/ML (70-30) SC CRTG", "INSULIN ASP PRT-INSULIN ASPART 100 UNIT/ML (70-30) SC SOLN", "INSULIN LISPRO 100 UNIT/ML SC INPH", "INSULIN NPH HUMAN SEMI-SYN 100 UNIT/ML SC CRTG", "INSULIN ASPART PROTAMINE-ASPART (70/30) 100 UNIT/ML SUBCUTANEOUS PEN", "INSULIN LISPRO PROTAM-LISPRO 100 UNIT/ML (75-25) SC SUSP", "INSULIN GLULISINE 100 UNIT/ML SC CRTG", "INSULIN DEGLUDEC-LIRAGLUTIDE 100 UNIT-3.6 MG /ML (3 ML) SC INPN", "INSULIN LISPRO PROTAM & LISPRO 100 UNIT/ML (75-25) SC SUSP", "INSULIN REGULAR HUM U-500 CONC 500 UNIT/ML SC SOLN", "INSULIN LISPRO 100 UNIT/ML SC CRTG", "INSULIN ASPART 100 UNIT/ML SC CRTG") -- removes anything ordered <10 times
       AND medord2.med_description NOT LIKE "%CRTG%" -- excludes anything ordered as a cartridge to remove pumps
       AND medord2.med_description NOT LIKE "%U-500%" -- exlcudes U-500
       AND medord2.med_route = 'Subcutaneous') --and subQ
     AND (mar.mar_action) IN ('Given') --medication actually given
   AND (mar.mar_action) NOT IN ('Bag Removal', 'Canceled Entry', 'Due', 'Existing Bag', 'Infusion Restarted', 'Infusion Started', 'Infusion Stopped', 'New Bag', 'Patch Removal', 'Patient\'s Own Med', 'Patient/Family Admin', 'Paused', 'Pending', 'Rate Changed', 'Rate Verify', 'Pump%', 'See Anesthesia Record', 'Self Administered Med', 'See Override Pull','Refused', 'Held', 'Stopped', 'Missed', 'Bolus', 'Complete', 'Completed', 'Push')
   AND mar.dose_unit_c = 5 -- "units", not an infusion (not units/hr)
   AND mar.sig <> "0-10"
   AND CAST(mar.sig AS float64) > 0
   -- AND CAST(mar.sig AS float64) < 100 --set maximum insulin at 100 to minimize recording errors
   AND mar.sig IS NOT NULL 
   AND mar.sig NOT LIKE "%.%" -- removes any partial unit injections (assumed to be pump)
   AND mar.infusion_rate IS NULL -- infusion_rate assumed to signify pump pt
   AND mar.pat_enc_csn_id_coded NOT IN (SELECT lab.pat_enc_csn_id_coded FROM `som-nero-phi-jonc101.starr_datalake2018.lab_result` as lab -- excludes patient encounters with creatinine >2 
    WHERE (lab_name) LIKE "Creatinine, Ser/Plas" --most common creatinine order
    AND ord_num_value != 9999999
    AND taken_time_jittered IS NOT null
    AND ord_num_value > 2)


-- 
-- Patient encounters for which short-acting insulin was ordered
-- SELECT mar.jc_uid, mar.pat_enc_csn_id_coded, mar.sig as units, mar.mar_action, medord.med_description, mar.route, medord.medication_id, medord.sig, mar.taken_time_jittered as instructions FROM `som-nero-phi-jonc101.starr_datalake2018.mar` as mar 
SELECT count(distinct(mar.pat_enc_csn_id_coded)) FROM `som-nero-phi-jonc101.starr_datalake2018.mar` as mar 
  LEFT JOIN `som-nero-phi-jonc101.starr_datalake2018.order_med` as medord on mar.order_med_id_coded=medord.order_med_id_coded 
  WHERE mar.order_med_id_coded in 
  (SELECT medord2.order_med_id_coded FROM `som-nero-phi-jonc101.starr_datalake2018.order_med` as medord2
       WHERE UPPER(medord2.med_description) LIKE '%INSULIN%'-- insulin ordered)
       AND (medord2.ordering_mode_c) = 2 -- inpatient
       AND UPPER(medord2.med_description) NOT LIKE '%PUMP%' --excludes pumps
       AND (medord2.med_description) NOT IN ("INSULIN NPH HUMAN RECOMB 100 UNIT/ML SC CRTG", "INSULIN LISPRO PROTAM-LISPRO 100 UNIT/ML (50-50) SC SUSP", "INSULIN GLARGINE 300 UNIT/ML (3 ML) SC INPN", "INSULIN NPH & REGULAR HUMAN 100 UNIT/ML (70-30) SC CRTG", "INSULIN NPH-REGULAR HUM S-SYN 100 UNIT/ML (70-30) SC CRTG", "INSULIN ASP PRT-INSULIN ASPART 100 UNIT/ML (70-30) SC SOLN", "INSULIN LISPRO 100 UNIT/ML SC INPH", "INSULIN NPH HUMAN SEMI-SYN 100 UNIT/ML SC CRTG", "INSULIN ASPART PROTAMINE-ASPART (70/30) 100 UNIT/ML SUBCUTANEOUS PEN", "INSULIN LISPRO PROTAM-LISPRO 100 UNIT/ML (75-25) SC SUSP", "INSULIN GLULISINE 100 UNIT/ML SC CRTG", "INSULIN DEGLUDEC-LIRAGLUTIDE 100 UNIT-3.6 MG /ML (3 ML) SC INPN", "INSULIN LISPRO PROTAM & LISPRO 100 UNIT/ML (75-25) SC SUSP", "INSULIN REGULAR HUM U-500 CONC 500 UNIT/ML SC SOLN", "INSULIN LISPRO 100 UNIT/ML SC CRTG", "INSULIN ASPART 100 UNIT/ML SC CRTG") -- removes anything ordered <10 times
       AND medord2.med_description NOT LIKE "%CRTG%" -- excludes anything ordered as a cartridge to remove pumps
       AND medord2.med_description NOT LIKE "%U-500%" -- exlcudes U-500
       AND medord2.med_route = 'Subcutaneous') --and subQ
     AND (mar.mar_action) IN ('Given') --medication actually given
   AND (mar.mar_action) NOT IN ('Bag Removal', 'Canceled Entry', 'Due', 'Existing Bag', 'Infusion Restarted', 'Infusion Started', 'Infusion Stopped', 'New Bag', 'Patch Removal', 'Patient\'s Own Med', 'Patient/Family Admin', 'Paused', 'Pending', 'Rate Changed', 'Rate Verify', 'Pump%', 'See Anesthesia Record', 'Self Administered Med', 'See Override Pull','Refused', 'Held', 'Stopped', 'Missed', 'Bolus', 'Complete', 'Completed', 'Push')
   AND mar.dose_unit_c = 5 -- "units", not an infusion (not units/hr)
   AND mar.sig <> "0-10"
   AND CAST(mar.sig AS float64) > 0
   -- AND CAST(mar.sig AS float64) < 100 --set maximum insulin at 100 to minimize recording errors
   AND mar.sig IS NOT NULL 
   AND mar.sig NOT LIKE "%.%" -- removes any partial unit injections (assumed to be pump)
   AND mar.infusion_rate IS NULL -- infusion_rate assumed to signify pump pt
   AND mar.pat_enc_csn_id_coded NOT IN (SELECT lab.pat_enc_csn_id_coded FROM `som-nero-phi-jonc101.starr_datalake2018.lab_result` as lab -- excludes patient encounters with creatinine >2 
    WHERE (lab_name) LIKE "Creatinine, Ser/Plas" --most common creatinine order
    AND ord_num_value != 9999999
    AND taken_time_jittered IS NOT null
    AND ord_num_value > 2)
   AND mar.pat_enc_csn_id_coded IN (SELECT medord2.pat_enc_csn_id_coded FROM `som-nero-phi-jonc101.starr_datalake2018.order_med` as medord2
       WHERE UPPER(medord2.med_description) LIKE '%INSULIN%'-- insulin ordered
       AND (medord2.ordering_mode_c) = 2 -- inpatient
       AND UPPER(medord2.med_description) NOT LIKE '%PUMP%' --excludes pumps
       AND (medord2.med_description) NOT IN ("INSULIN NPH HUMAN RECOMB 100 UNIT/ML SC CRTG", "INSULIN LISPRO PROTAM-LISPRO 100 UNIT/ML (50-50) SC SUSP", "INSULIN GLARGINE 300 UNIT/ML (3 ML) SC INPN", "INSULIN NPH & REGULAR HUMAN 100 UNIT/ML (70-30) SC CRTG", "INSULIN NPH-REGULAR HUM S-SYN 100 UNIT/ML (70-30) SC CRTG", "INSULIN ASP PRT-INSULIN ASPART 100 UNIT/ML (70-30) SC SOLN", "INSULIN LISPRO 100 UNIT/ML SC INPH", "INSULIN NPH HUMAN SEMI-SYN 100 UNIT/ML SC CRTG", "INSULIN ASPART PROTAMINE-ASPART (70/30) 100 UNIT/ML SUBCUTANEOUS PEN", "INSULIN LISPRO PROTAM-LISPRO 100 UNIT/ML (75-25) SC SUSP", "INSULIN GLULISINE 100 UNIT/ML SC CRTG", "INSULIN DEGLUDEC-LIRAGLUTIDE 100 UNIT-3.6 MG /ML (3 ML) SC INPN", "INSULIN LISPRO PROTAM & LISPRO 100 UNIT/ML (75-25) SC SUSP", "INSULIN REGULAR HUM U-500 CONC 500 UNIT/ML SC SOLN", "INSULIN LISPRO 100 UNIT/ML SC CRTG", "INSULIN ASPART 100 UNIT/ML SC CRTG") -- removes anything ordered <10 times
       AND medord2.med_description NOT LIKE "%CRTG%" -- excludes anything ordered as a cartridge to remove pumps
       AND medord2.med_description NOT LIKE "%U-500%" -- exlcudes U-500
       AND medord2.med_route = 'Subcutaneous' --and subQ
       AND UPPER(medord2.med_description) LIKE "%SCALE%"
       )

-- Patient encounters for which ISS (explicitly "scale") alone was ordered (basal excluded)
SELECT medord.med_description, count(medord.med_description) as count FROM `som-nero-phi-jonc101.starr_datalake2018.mar` as mar 
-- SELECT mar.jc_uid, mar.pat_enc_csn_id_coded, mar.sig as units, mar.mar_action, medord.med_description, mar.route, medord.medication_id, medord.sig, mar.taken_time_jittered as instructions FROM `som-nero-phi-jonc101.starr_datalake2018.mar` as mar 
-- SELECT count(distinct(mar.pat_enc_csn_id_coded)) FROM `som-nero-phi-jonc101.starr_datalake2018.mar` as mar 
  LEFT JOIN `som-nero-phi-jonc101.starr_datalake2018.order_med` as medord on mar.order_med_id_coded=medord.order_med_id_coded 
  WHERE mar.order_med_id_coded in 
  (SELECT medord2.order_med_id_coded FROM `som-nero-phi-jonc101.starr_datalake2018.order_med` as medord2
       WHERE UPPER(medord2.med_description) LIKE '%INSULIN%'-- insulin ordered)
       AND (medord2.ordering_mode_c) = 2 -- inpatient
       AND UPPER(medord2.med_description) NOT LIKE '%PUMP%' --excludes pumps
       AND (medord2.med_description) NOT IN ("INSULIN NPH HUMAN RECOMB 100 UNIT/ML SC CRTG", "INSULIN LISPRO PROTAM-LISPRO 100 UNIT/ML (50-50) SC SUSP", "INSULIN GLARGINE 300 UNIT/ML (3 ML) SC INPN", "INSULIN NPH & REGULAR HUMAN 100 UNIT/ML (70-30) SC CRTG", "INSULIN NPH-REGULAR HUM S-SYN 100 UNIT/ML (70-30) SC CRTG", "INSULIN ASP PRT-INSULIN ASPART 100 UNIT/ML (70-30) SC SOLN", "INSULIN LISPRO 100 UNIT/ML SC INPH", "INSULIN NPH HUMAN SEMI-SYN 100 UNIT/ML SC CRTG", "INSULIN ASPART PROTAMINE-ASPART (70/30) 100 UNIT/ML SUBCUTANEOUS PEN", "INSULIN LISPRO PROTAM-LISPRO 100 UNIT/ML (75-25) SC SUSP", "INSULIN GLULISINE 100 UNIT/ML SC CRTG", "INSULIN DEGLUDEC-LIRAGLUTIDE 100 UNIT-3.6 MG /ML (3 ML) SC INPN", "INSULIN LISPRO PROTAM & LISPRO 100 UNIT/ML (75-25) SC SUSP", "INSULIN REGULAR HUM U-500 CONC 500 UNIT/ML SC SOLN", "INSULIN LISPRO 100 UNIT/ML SC CRTG", "INSULIN ASPART 100 UNIT/ML SC CRTG") -- removes anything ordered <10 times
       AND medord2.med_description NOT LIKE "%CRTG%" -- excludes anything ordered as a cartridge to remove pumps
       AND medord2.med_description NOT LIKE "%U-500%" -- exlcudes U-500
       AND UPPER(medord2.med_description) LIKE '%SCALE%'
       AND medord2.med_route = 'Subcutaneous') --and subQ
     AND (mar.mar_action) IN ('Given') --medication actually given
   AND (mar.mar_action) NOT IN ('Bag Removal', 'Canceled Entry', 'Due', 'Existing Bag', 'Infusion Restarted', 'Infusion Started', 'Infusion Stopped', 'New Bag', 'Patch Removal', 'Patient\'s Own Med', 'Patient/Family Admin', 'Paused', 'Pending', 'Rate Changed', 'Rate Verify', 'Pump%', 'See Anesthesia Record', 'Self Administered Med', 'See Override Pull','Refused', 'Held', 'Stopped', 'Missed', 'Bolus', 'Complete', 'Completed', 'Push')
   AND mar.dose_unit_c = 5 -- "units", not an infusion (not units/hr)
   AND mar.sig <> "0-10"
   AND CAST(mar.sig AS float64) > 0
   -- AND CAST(mar.sig AS float64) < 100 --set maximum insulin at 100 to minimize recording errors
   AND mar.sig IS NOT NULL 
   AND mar.sig NOT LIKE "%.%" -- removes any partial unit injections (assumed to be pump)
   AND mar.infusion_rate IS NULL -- infusion_rate assumed to signify pump pt
   AND mar.pat_enc_csn_id_coded NOT IN (SELECT lab.pat_enc_csn_id_coded FROM `som-nero-phi-jonc101.starr_datalake2018.lab_result` as lab -- excludes patient encounters with creatinine >2 
    WHERE (lab_name) LIKE "Creatinine, Ser/Plas" --most common creatinine order
    AND ord_num_value != 9999999
    AND taken_time_jittered IS NOT null
    AND ord_num_value > 2)
   AND mar.pat_enc_csn_id_coded IN (SELECT medord2.pat_enc_csn_id_coded FROM `som-nero-phi-jonc101.starr_datalake2018.order_med` as medord2
       WHERE UPPER(medord2.med_description) LIKE '%INSULIN%'-- insulin ordered
       AND (medord2.ordering_mode_c) = 2 -- inpatient
       AND UPPER(medord2.med_description) NOT LIKE '%PUMP%' --excludes pumps
       AND (medord2.med_description) NOT IN ("INSULIN NPH HUMAN RECOMB 100 UNIT/ML SC CRTG", "INSULIN LISPRO PROTAM-LISPRO 100 UNIT/ML (50-50) SC SUSP", "INSULIN GLARGINE 300 UNIT/ML (3 ML) SC INPN", "INSULIN NPH & REGULAR HUMAN 100 UNIT/ML (70-30) SC CRTG", "INSULIN NPH-REGULAR HUM S-SYN 100 UNIT/ML (70-30) SC CRTG", "INSULIN ASP PRT-INSULIN ASPART 100 UNIT/ML (70-30) SC SOLN", "INSULIN LISPRO 100 UNIT/ML SC INPH", "INSULIN NPH HUMAN SEMI-SYN 100 UNIT/ML SC CRTG", "INSULIN ASPART PROTAMINE-ASPART (70/30) 100 UNIT/ML SUBCUTANEOUS PEN", "INSULIN LISPRO PROTAM-LISPRO 100 UNIT/ML (75-25) SC SUSP", "INSULIN GLULISINE 100 UNIT/ML SC CRTG", "INSULIN DEGLUDEC-LIRAGLUTIDE 100 UNIT-3.6 MG /ML (3 ML) SC INPN", "INSULIN LISPRO PROTAM & LISPRO 100 UNIT/ML (75-25) SC SUSP", "INSULIN REGULAR HUM U-500 CONC 500 UNIT/ML SC SOLN", "INSULIN LISPRO 100 UNIT/ML SC CRTG", "INSULIN ASPART 100 UNIT/ML SC CRTG") -- removes anything ordered <10 times
       AND medord2.med_description NOT LIKE "%CRTG%" -- excludes anything ordered as a cartridge to remove pumps
       AND medord2.med_description NOT LIKE "%U-500%" -- exlcudes U-500
       AND medord2.med_route = 'Subcutaneous' --and subQ
       AND UPPER(medord2.med_description) LIKE "%SCALE%")
  -- EXCLUDING PATIENTS ORDERED FOR BASAL
    AND mar.pat_enc_csn_id_coded NOT IN (SELECT medord2.pat_enc_csn_id_coded FROM `som-nero-phi-jonc101.starr_datalake2018.order_med` as medord2 -- excludes patients who had basal insulin ordered * except for 2 orders of NPH that are excluded above
       WHERE UPPER(medord2.med_description) LIKE '%INSULIN%'-- insulin ordered
       AND (medord2.ordering_mode_c) = 2 -- inpatient
       AND UPPER(medord2.med_description) NOT LIKE '%PUMP%' --excludes pumps
       AND (medord2.med_description) NOT IN ("INSULIN NPH HUMAN RECOMB 100 UNIT/ML SC CRTG", "INSULIN LISPRO PROTAM-LISPRO 100 UNIT/ML (50-50) SC SUSP", "INSULIN GLARGINE 300 UNIT/ML (3 ML) SC INPN", "INSULIN NPH & REGULAR HUMAN 100 UNIT/ML (70-30) SC CRTG", "INSULIN NPH-REGULAR HUM S-SYN 100 UNIT/ML (70-30) SC CRTG", "INSULIN ASP PRT-INSULIN ASPART 100 UNIT/ML (70-30) SC SOLN", "INSULIN LISPRO 100 UNIT/ML SC INPH", "INSULIN NPH HUMAN SEMI-SYN 100 UNIT/ML SC CRTG", "INSULIN ASPART PROTAMINE-ASPART (70/30) 100 UNIT/ML SUBCUTANEOUS PEN", "INSULIN LISPRO PROTAM-LISPRO 100 UNIT/ML (75-25) SC SUSP", "INSULIN GLULISINE 100 UNIT/ML SC CRTG", "INSULIN DEGLUDEC-LIRAGLUTIDE 100 UNIT-3.6 MG /ML (3 ML) SC INPN", "INSULIN LISPRO PROTAM & LISPRO 100 UNIT/ML (75-25) SC SUSP", "INSULIN REGULAR HUM U-500 CONC 500 UNIT/ML SC SOLN", "INSULIN LISPRO 100 UNIT/ML SC CRTG", "INSULIN ASPART 100 UNIT/ML SC CRTG") -- removes anything ordered <10 times
       AND medord2.med_description NOT LIKE "%CRTG%" -- excludes anything ordered as a cartridge to remove pumps
       AND medord2.med_description NOT LIKE "%U-500%" -- exlcudes U-500
       AND medord2.med_route = 'Subcutaneous' --and subQ
       AND UPPER(medord2.med_description) IN ("INSULIN NPH HUMAN RECOMB 100 UNIT/ML SC SUSP", "NPH INSULIN HUMAN RECOMB 100 UNIT/ML SC SUSP", "INSULIN GLARGINE 100 UNIT/ML SC SOLN", "INSULIN DETEMIR 100 UNIT/ML SC SOLN", "INSULIN NPH ISOPH U-100 HUMAN 100 UNIT/ML SC SUSP", "INSULIN DETEMIR U-100 100 UNIT/ML (3 ML) SC INPN", "INSULIN NPH & REGULAR HUMAN 100 UNIT/ML (70-30) SC SUSP", "INSULIN NPH AND REGULAR HUMAN 100 UNIT/ML (70-30) SC SUSP", "INSULIN NPH AND REGULAR HUMAN 100 UNIT/ML (70/30) SUBCUTANEOUS VIAL", "INSULIN DETEMIR 100 UNIT/ML (3 ML) SC INPN", "INSULIN DETEMIR U-100 100 UNIT/ML SC SOLN", "INSULIN DEGLUDEC 100 UNIT/ML (3 ML) SC INPN", "INSULIN NPH & REGULAR HUMAN 100 UNIT/ML (50-50) SC SUSP", "INSULIN LISPRO PROTAM & LISPRO 100 UNIT/ML (75-25) SC INPN", "INSULIN LISPRO PROTAMIN-LISPRO 100 UNIT/ML (75-25) SC INPN", "INSULIN GLARGINE 300 UNIT/3 ML SC INPN", "INSULIN GLARGINE 300 UNIT/ML (1.5 ML) SC INPN", "INSULIN DEGLUDEC 200 UNIT/ML (3 ML) SC INPN", "INSULIN GLARGINE 100 UNIT/ML (3 ML) SC INPN", "INSULIN NPH AND REGULAR HUMAN 100 UNIT/ML (70-30) SC SUSP", "INSULIN NPH HUMAN RECOMB 100 UNIT/ML SC SUSP","INSULIN DETEMIR 100 UNIT/ML SC INPN", "INSULIN ASP PRT-INSULIN ASPART 100 UNIT/ML (70-30) SC INPN") -- patients ordered for basal
       ) 
   --  */
GROUP BY medord.med_description       
ORDER BY count ASC
-- AND taken_time_jittered BETWEEN "2008-01-01T00:00:00" AND "2008-12-31T23:59:59"




--
-- Patient encounters for which basal insulin was not ordered
-- SELECT mar.jc_uid, mar.pat_enc_csn_id_coded, mar.sig as units, mar.mar_action, medord.med_description, mar.route, medord.medication_id, medord.sig, mar.taken_time_jittered as instructions FROM `som-nero-phi-jonc101.starr_datalake2018.mar` as mar 
-- SELECT mar.jc_uid, mar.pat_enc_csn_id_coded, mar.sig as units, mar.mar_action, medord.med_description, mar.route, medord.medication_id, medord.sig, mar.taken_time_jittered as instructions FROM `som-nero-phi-jonc101.starr_datalake2018.mar` as mar 
-- SELECT count(distinct(mar.pat_enc_csn_id_coded)) FROM `som-nero-phi-jonc101.starr_datalake2018.mar` as mar 
SELECT medord.med_description, COUNT(medord.med_description) as count FROM `som-nero-phi-jonc101.starr_datalake2018.mar` as mar 
  LEFT JOIN `som-nero-phi-jonc101.starr_datalake2018.order_med` as medord on mar.order_med_id_coded=medord.order_med_id_coded 
  WHERE mar.order_med_id_coded in 
  (SELECT medord2.order_med_id_coded FROM `som-nero-phi-jonc101.starr_datalake2018.order_med` as medord2
       WHERE UPPER(medord2.med_description) LIKE '%INSULIN%'-- insulin ordered)
       AND (medord2.ordering_mode_c) = 2 -- inpatient
       AND UPPER(medord2.med_description) NOT LIKE '%PUMP%' --excludes pumps
       AND (medord2.med_description) NOT IN ("INSULIN NPH HUMAN RECOMB 100 UNIT/ML SC CRTG", "INSULIN LISPRO PROTAM-LISPRO 100 UNIT/ML (50-50) SC SUSP", "INSULIN GLARGINE 300 UNIT/ML (3 ML) SC INPN", "INSULIN NPH & REGULAR HUMAN 100 UNIT/ML (70-30) SC CRTG", "INSULIN NPH-REGULAR HUM S-SYN 100 UNIT/ML (70-30) SC CRTG", "INSULIN ASP PRT-INSULIN ASPART 100 UNIT/ML (70-30) SC SOLN", "INSULIN LISPRO 100 UNIT/ML SC INPH", "INSULIN NPH HUMAN SEMI-SYN 100 UNIT/ML SC CRTG", "INSULIN ASPART PROTAMINE-ASPART (70/30) 100 UNIT/ML SUBCUTANEOUS PEN", "INSULIN LISPRO PROTAM-LISPRO 100 UNIT/ML (75-25) SC SUSP", "INSULIN GLULISINE 100 UNIT/ML SC CRTG", "INSULIN DEGLUDEC-LIRAGLUTIDE 100 UNIT-3.6 MG /ML (3 ML) SC INPN", "INSULIN LISPRO PROTAM & LISPRO 100 UNIT/ML (75-25) SC SUSP", "INSULIN REGULAR HUM U-500 CONC 500 UNIT/ML SC SOLN", "INSULIN LISPRO 100 UNIT/ML SC CRTG", "INSULIN ASPART 100 UNIT/ML SC CRTG") -- removes anything ordered <10 times
       AND medord2.med_description NOT LIKE "%CRTG%" -- excludes anything ordered as a cartridge to remove pumps
       AND medord2.med_description NOT LIKE "%U-500%" -- exlcudes U-500
       AND medord2.med_description NOT IN ("INSULIN NPH AND REGULAR HUMAN 100 UNIT/ML (70-30) SC SUSP", "INSULIN NPH HUMAN RECOMB 100 UNIT/ML SC SUSP") -- removes 2 basal doses that were not excluded by basal clause below
       AND medord2.med_route = 'Subcutaneous') --and subQ
     AND (mar.mar_action) IN ('Given') --medication actually given
   AND (mar.mar_action) NOT IN ('Bag Removal', 'Canceled Entry', 'Due', 'Existing Bag', 'Infusion Restarted', 'Infusion Started', 'Infusion Stopped', 'New Bag', 'Patch Removal', 'Patient\'s Own Med', 'Patient/Family Admin', 'Paused', 'Pending', 'Rate Changed', 'Rate Verify', 'Pump%', 'See Anesthesia Record', 'Self Administered Med', 'See Override Pull','Refused', 'Held', 'Stopped', 'Missed', 'Bolus', 'Complete', 'Completed', 'Push')
   AND mar.dose_unit_c = 5 -- "units", not an infusion (not units/hr)
   AND mar.sig <> "0-10"
   AND CAST(mar.sig AS float64) > 0
   -- AND CAST(mar.sig AS float64) < 100 --set maximum insulin at 100 to minimize recording errors
   AND mar.sig IS NOT NULL 
   AND mar.sig NOT LIKE "%.%" -- removes any partial unit injections (assumed to be pump)
   AND mar.infusion_rate IS NULL -- infusion_rate assumed to signify pump pt
   AND mar.pat_enc_csn_id_coded NOT IN (SELECT lab.pat_enc_csn_id_coded FROM `som-nero-phi-jonc101.starr_datalake2018.lab_result` as lab -- excludes patient encounters with creatinine >2 
    WHERE (lab_name) LIKE "Creatinine, Ser/Plas" --most common creatinine order
    AND ord_num_value != 9999999
    AND taken_time_jittered IS NOT null
    AND ord_num_value > 2)
   AND mar.pat_enc_csn_id_coded NOT IN (SELECT medord2.pat_enc_csn_id_coded FROM `som-nero-phi-jonc101.starr_datalake2018.order_med` as medord2
       WHERE UPPER(medord2.med_description) LIKE '%INSULIN%'-- insulin ordered
       AND (medord2.ordering_mode_c) = 2 -- inpatient
       AND UPPER(medord2.med_description) NOT LIKE '%PUMP%' --excludes pumps
       AND (medord2.med_description) NOT IN ("INSULIN NPH HUMAN RECOMB 100 UNIT/ML SC CRTG", "INSULIN LISPRO PROTAM-LISPRO 100 UNIT/ML (50-50) SC SUSP", "INSULIN GLARGINE 300 UNIT/ML (3 ML) SC INPN", "INSULIN NPH & REGULAR HUMAN 100 UNIT/ML (70-30) SC CRTG", "INSULIN NPH-REGULAR HUM S-SYN 100 UNIT/ML (70-30) SC CRTG", "INSULIN ASP PRT-INSULIN ASPART 100 UNIT/ML (70-30) SC SOLN", "INSULIN LISPRO 100 UNIT/ML SC INPH", "INSULIN NPH HUMAN SEMI-SYN 100 UNIT/ML SC CRTG", "INSULIN ASPART PROTAMINE-ASPART (70/30) 100 UNIT/ML SUBCUTANEOUS PEN", "INSULIN LISPRO PROTAM-LISPRO 100 UNIT/ML (75-25) SC SUSP", "INSULIN GLULISINE 100 UNIT/ML SC CRTG", "INSULIN DEGLUDEC-LIRAGLUTIDE 100 UNIT-3.6 MG /ML (3 ML) SC INPN", "INSULIN LISPRO PROTAM & LISPRO 100 UNIT/ML (75-25) SC SUSP", "INSULIN REGULAR HUM U-500 CONC 500 UNIT/ML SC SOLN", "INSULIN LISPRO 100 UNIT/ML SC CRTG", "INSULIN ASPART 100 UNIT/ML SC CRTG") -- removes anything ordered <10 times
       AND medord2.med_description NOT LIKE "%CRTG%" -- excludes anything ordered as a cartridge to remove pumps
       AND medord2.med_description NOT LIKE "%U-500%" -- exlcudes U-500
       AND medord2.med_route = 'Subcutaneous' --and subQ
       AND UPPER(medord2.med_description) IN ("INSULIN NPH HUMAN RECOMB 100 UNIT/ML SC SUSP", "NPH INSULIN HUMAN RECOMB 100 UNIT/ML SC SUSP", "INSULIN GLARGINE 100 UNIT/ML SC SOLN", "INSULIN DETEMIR 100 UNIT/ML SC SOLN", "INSULIN NPH ISOPH U-100 HUMAN 100 UNIT/ML SC SUSP", "INSULIN DETEMIR U-100 100 UNIT/ML (3 ML) SC INPN", "INSULIN NPH & REGULAR HUMAN 100 UNIT/ML (70-30) SC SUSP", "INSULIN NPH AND REGULAR HUMAN 100 UNIT/ML (70-30) SC SUSP", "INSULIN NPH AND REGULAR HUMAN 100 UNIT/ML (70/30) SUBCUTANEOUS VIAL", "INSULIN DETEMIR 100 UNIT/ML (3 ML) SC INPN", "INSULIN DETEMIR U-100 100 UNIT/ML SC SOLN", "INSULIN DEGLUDEC 100 UNIT/ML (3 ML) SC INPN", "INSULIN NPH & REGULAR HUMAN 100 UNIT/ML (50-50) SC SUSP", "INSULIN LISPRO PROTAM & LISPRO 100 UNIT/ML (75-25) SC INPN", "INSULIN LISPRO PROTAMIN-LISPRO 100 UNIT/ML (75-25) SC INPN", "INSULIN GLARGINE 300 UNIT/3 ML SC INPN", "INSULIN GLARGINE 300 UNIT/ML (1.5 ML) SC INPN", "INSULIN DEGLUDEC 200 UNIT/ML (3 ML) SC INPN", "INSULIN GLARGINE 100 UNIT/ML (3 ML) SC INPN", "INSULIN NPH AND REGULAR HUMAN 100 UNIT/ML (70-30) SC SUSP", "INSULIN NPH HUMAN RECOMB 100 UNIT/ML SC SUSP","INSULIN DETEMIR 100 UNIT/ML SC INPN", "INSULIN ASP PRT-INSULIN ASPART 100 UNIT/ML (70-30) SC INPN") -- patients ordered for basal
       )
--ORDER BY medord.med_description 
GROUP BY medord.med_description
ORDER BY count desc




