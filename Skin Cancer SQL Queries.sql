--rename table NAMES
ALTER TABLE TABLE1 RENAME TO Patients;
ALTER TABLE TABLE2 RENAME TO lesions;

--Join table1 and table2
SELECT table1.patient_id,table1.skin_cancer_history,table1.cancer_history,
biopsed,lesion_id 
from 
	table1 
left join 
		table2 
On table2.patient_id = table1.patient_id;

SELECT table1.patient_id,table1.skin_cancer_history,table1.cancer_history,
biopsed,lesion_id 
from 
	table1 
Full join 
		table2 
On table2.patient_id = table1.patient_id;

--Total number of patient in the DATABASE
SELECT count(patient_id) as Total_patient from patients;

--total skin cancer patients
SELECT count(patient_id) as Skin_Cancer_patient
from patients
where skin_cancer_history ='true'
group by skin_cancer_history;

--2. Which lesion types are most common among patients with a history of skin cancer?---
SELECT 
    lesions.diagnostic,
    COUNT(*) AS LesionCount
FROM lesions
JOIN patients ON lesions.patient_id = patients.patient_id
WHERE patients.skin_cancer_history = TRUE
GROUP BY lesions.diagnostic
ORDER BY lesionCount DESC;

--Age group most affected by skin cancer
SELECT 
    CASE 
        WHEN age BETWEEN 0 AND 19 THEN '0-19'
        WHEN age BETWEEN 20 AND 29 THEN '20-29'
        WHEN age BETWEEN 30 AND 39 THEN '30-39'
        WHEN age BETWEEN 40 AND 49 THEN '40-49'
        WHEN age BETWEEN 50 AND 59 THEN '50-59'
        WHEN age BETWEEN 60 AND 69 THEN '60-69'
        WHEN age BETWEEN 70 AND 79 THEN '70-79'
        WHEN age BETWEEN 80 AND 89 THEN '80-89'
        WHEN age BETWEEN 90 AND 100 THEN '90-100'
        ELSE 'Unknown'
    END AS age_group,
    COUNT(*) AS skin_cancer_cases
FROM 
    patients
WHERE 
    skin_cancer_history = 'true'
GROUP BY 
    age_group
ORDER BY 
    skin_cancer_cases desc;

--Gender most affected by skin cancer
SELECT 
    gender, 
    COUNT(*) AS skin_cancer_case_count
FROM 
    patients
WHERE 
    skin_cancer_history= 'True'
GROUP BY 
    gender
ORDER BY 
    skin_cancer_case_count DESC;
	
--Do patients with known Drinking habits show a higher rate of cancer
SELECT 
    drink,
    COUNT(*) AS total_patients,
    SUM(CASE WHEN cancer_history = 'True' THEN 1 ELSE 0 END) AS cancer_cases,
    ROUND(
        SUM(CASE WHEN cancer_history = 'true' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 
        2
    ) AS cancer_rate_percent
FROM 
    patients
GROUP BY 
    drink;
	
--Do patients with known Smoking habits show a higher rate of cancer
SELECT 
    smoke,
    COUNT(*) AS total_patients,
    SUM(CASE WHEN cancer_history = 'True' THEN 1 ELSE 0 END) AS cancer_cases,
    ROUND(
        SUM(CASE WHEN cancer_history = 'true' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 
        2
    ) AS cancer_rate_percent
FROM 
    patients
GROUP BY 
    smoke;
--lesion region and malignancy(biopsed)
SELECT 
    region,
    COUNT(*) AS total_lesions,
    SUM(CASE WHEN biopsed = 'true' THEN 1 ELSE 0 END) AS malignant_cases,
    ROUND(SUM(CASE WHEN biopsed = 'true' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS malignancy_rate_percent
FROM 
    table2
GROUP BY 
    region
ORDER BY 
    malignancy_rate_percent DESC;
	
--lesion size and malignancy trend

SELECT 
    CASE 
        WHEN diameter_1 < 5 THEN 'Small (<5mm)'
        WHEN diameter_1 BETWEEN 5 AND 9 THEN 'Medium (5–9mm)'
        WHEN diameter_1 >= 10 THEN 'Large (10mm+)'
        ELSE 'Unknown'
    END AS lesion_size_group,
    COUNT(*) AS total_lesions,
    SUM(CASE WHEN biopsed = 'true' THEN 1 ELSE 0 END) AS malignant_cases,
    ROUND(SUM(CASE WHEN biopsed = 'true' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS malignancy_rate_percent
FROM 
    lesions
GROUP BY 
    lesion_size_group
ORDER BY 
    malignancy_rate_percent DESC;
	
--4. Compare lesion sizes (average of diameter_1 and diameter_2) between smokers and non-smokers
SELECT 
    patients.smoke,
    ROUND(AVG((lesions.diameter_1 + lesions.diameter_2) / 2.0)::numeric, 2) AS avg_lesion_size
FROM lesions
JOIN patients ON lesions.patient_id = patients.patient_id
GROUP BY patients.smoke;

-- What percentage of biopsied lesions are from patients without piped water?---
SELECT 
    COUNT(*) FILTER (WHERE patients.has_piped_water = FALSE) * 100.0 / COUNT(*) AS percent_biopsied_without_piped_water
FROM lesions
JOIN patients ON lesions.patient_id = patients.patient_id
WHERE lesions.biopsed = TRUE;

SELECT 
    COUNT(*) AS symptomatic_lesions
FROM lesions
JOIN patients ON lesions.patient_id = patients.patient_id
WHERE patients.cancer_history = TRUE
  AND (lesions.itch = TRUE OR lesions.bleed = TRUE);

--9. Do patients with environmental risk (pesticide exposure) tend to have larger lesions?--
SELECT 
    patients.pesticide,
    ROUND(AVG((lesions.diameter_1 + lesions.diameter_2) / 2.0)::numeric, 2) AS avg_size
FROM lesions
JOIN patients ON lesions.patient_id = patients.patient_id
GROUP BY patients.pesticide
order by avg_size desc;

--10. Get all lesion records where the patient is over 60, has a family history of cancer, and the lesion was biopsied.--
SELECT 
    lesions.*, 
    patients.age, 
    patients.cancer_history
FROM lesions
JOIN patients ON lesions.patient_id = patients.patient_id
WHERE patients.age > 50
  AND patients.cancer_history = TRUE
  AND lesions.biopsed = TRUE;

---1  Does pesticide exposure correlate with malignant lesion types?----
SELECT 
	patients.pesticide,
    lesions.diagnostic,
    COUNT(*) AS lesion_count
FROM lesions
JOIN patients ON lesions.patient_id = patients.patient_id
GROUP BY patients.pesticide, lesions.diagnostic
ORDER BY patients.pesticide, lesion_count DESC;


--How balanced is the dataset across different skin cancer types?
SELECT 
    diagnostic,
    COUNT(*) AS case_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM table2), 2) AS percentage_of_total
FROM 
    table2
GROUP BY 
    diagnostic
ORDER BY 
    case_count DESC;

--What are the most frequent combinations of lesion and patient features leading to malignancy?
SELECT 
    CASE 
        WHEN table1.age BETWEEN 0 AND 19 THEN '0-19'
        WHEN table1.age BETWEEN 20 AND 29 THEN '20-29'
        WHEN table1.age BETWEEN 30 AND 39 THEN '30-39'
        WHEN table1.age BETWEEN 40 AND 49 THEN '40-49'
        WHEN table1.age BETWEEN 50 AND 59 THEN '50-59'
        WHEN table1.age BETWEEN 60 AND 69 THEN '60-69'
        WHEN table1.age BETWEEN 70 AND 79 THEN '70-79'
		WHEN table1.age BETWEEN 70 AND 79 THEN '80-89'
        WHEN table1.age BETWEEN 80 AND 100 THEN '90-100'
        ELSE 'Unknown'
    END AS age_group,
    table1.gender,
    table2.region,
    COUNT(*) AS malignant_case_count
FROM 
    table2
JOIN 
    table1 ON table2.patient_id = table1.patient_id
WHERE 
    table2.diagnostic = 'true'
GROUP BY 
    age_group, table1.gender,table2.region
ORDER BY 
    malignant_case_count DESC
LIMIT 10;


---2. Is lesion size (diameter) a strong indicator of cancerous lesions?----
SELECT 
    diagnostic,
    ROUND(AVG((diameter_1 + diameter_2)/2.0)::numeric, 2) AS avg_lesion_size,
    MIN((diameter_1 + diameter_2)/2.0) AS min_size,
    MAX((diameter_1 + diameter_2)/2.0) AS max_size,
    COUNT(*) AS lesion_count
FROM lesions
GROUP BY diagnostic
ORDER BY avg_lesion_size DESC;


