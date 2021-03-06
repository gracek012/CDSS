#!/usr/bin/env python

"""
Download the detailed Medicare Part D Drug Prescription data file from the page below
https://www.cms.gov/Research-Statistics-Data-and-Systems/Statistics-Trends-and-Reports/Medicare-Provider-Charge-Data/PartD2015.html

    Part D Prescriber PUF NPI Drug, CY2015, (Tab Delimited Format) [552MB]
    http://download.cms.gov/Research-Statistics-Data-and-Systems/Statistics-Trends-and-Reports/Medicare-Provider-Charge-Data/Downloads/PartD_Prescriber_PUF_NPI_DRUG_15.zip

The file represents a large data file tracking individual doctors by "npi" (ID number), 
along with the drugs they prescribed, identified by "generic_name"
and total prescriptions by "total_claim_count".

Design and implement application code in this class to
Scan through the input data file of who prescribed which drugs,
and determine which other "drug B's" are also prescribed
for those who prescribe drug A.

Return a list of 2-ples with non-zero values below, sorted in descending order
    - Number of prescribers prescribing drugs A and B ("Support")
    - Generic name of drug B

HINT:
- Data assumed to already be sorted in order by prescriber npi unique identifier
- zipfile package facilitates reading from ZIP files
- csv.DictReader can facilitate reading over tab-delimited file


Create a respective unit test script/program that verifies correct functionality of your program.
Complete the code implementation below such that results can be calculated from the command-line. For example, running

    python AssociationStatsExample.py PartD_Prescriber_PUF_NPI_DRUG_15.zip AZITHROMYCIN

Should result in output similar to...

    (180431, 'AZITHROMYCIN')
    (132454, 'OMEPRAZOLE')
    (129860, 'LISINOPRIL')
    (128944, 'AMLODIPINE BESYLATE')
    (128887, 'LEVOTHYROXINE SODIUM')
    (128786, 'PREDNISONE')
    (126266, 'ALBUTEROL SULFATE')
    (126127, 'ATORVASTATIN CALCIUM')
    (124496, 'FUROSEMIDE')
    (123981, 'SIMVASTATIN')
    (123915, 'METFORMIN HCL')
    (123578, 'FLUTICASONE PROPIONATE')
    (120314, 'HYDROCHLOROTHIAZIDE')
    ...

"""
import sys, os;
import zipfile;
import csv;

class AssociationStatsExample:
    """Application module with example functions to implement and test.
    """
    def __init__(self):
        """Initialization constructor"""
        pass;
        
    ###################### START CODE HERE ########################
    ###################### START CODE HERE ########################
    ###################### START CODE HERE ########################
    ###################### START CODE HERE ########################
    
    ###################### END CODE HERE ########################
    ###################### END CODE HERE ########################
    ###################### END CODE HERE ########################
    ###################### END CODE HERE ########################

if __name__ == "__main__":
    # Command-line execution should start here and attempt to run the primary function and print results to the console
    zipFilename = sys.argv[1];
    drugA = sys.argv[2];
    
    instance = AssociationStatsExample();
    for (support, drugB) in #????:
        print (support, drugB);
