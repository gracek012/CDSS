#!/usr/bin/env python
"""
Given a set of clinical data sources output a patient episode feature matrix
for machine learning and regression applications.

Usage follows the following idiom:
factory = FeatureMatrixFactory()
factory.setFooInput()
factory.setBarInput()
...
factory.buildFeatureMatrix()
matrix = factory.getMatrixAsBaz()
"""

import csv
import datetime
import os
import time

from medinfo.cpoe.Const import SECONDS_PER_DAY, DELTA_NAME_BY_DAYS
from medinfo.db import DBUtil
from medinfo.db.Model import columnFromModelList, SQLQuery
from medinfo.db.ResultsFormatter import TabDictReader, TextResultsFormatter
from psycopg2.extensions import cursor
from Util import log

class FeatureMatrixFactory:
    FEATURE_MATRIX_COLUMN_NAMES = [
        "patient_id"
    ]

    def __init__(self, cacheDBResults = True):
        self.dbCache = None
        self.patientListInput = None
        self.patientIdColumn = None
        self.patientEpisodeInput = None
        self.patientEpisodeIdColumn = None
        self._patientItemTimeColumn = None
        self.timestampColumn = None

        self.patientsProcessed = None

        self._patientListTempFileName = "fmf.patient_list.tsv"
        self._patientEpisodeTempFileName = "fmf.patient_episodes.tsv"
        self._patientItemTempFileNameFormat = "fmf.patient_%s.tsv"
        self._matrixFileName = None

        # Look at lab results from the previous days
        LAB_PRE_TIME_DELTAS = [
            timedelta(-1), timedelta(-3), timedelta(-7), timedelta(-30),
            timedelta(-90)
        ]
        # Don't look into the future, otherwise cheating the prediction
        LAB_POST_TIME_DELTA = timedelta(+0)

        self._featureTempFileNames = []
        if cacheDBResults:
            self.dbCache = dict()

    def setPatientListInput(self, patientListInput, \
        patientIdColumn = "patient_id"):
        """
        Define the input patient list for the feature matrix.
        patientListInput: TSV file descriptor or DB cursor
        patientIdColumn: Name of TSV column or DB column.
        """
        # Verify patientListInput is TSV file or DB cursor.
        if not isinstance(patientListInput, cursor) and \
            not isinstance(patientListInput, file):
            raise TypeError("patientListInput must be DB cursor or TSV file.")

        self.patientListInput = patientListInput
        self.patientIdColumn = patientIdColumn
        pass

    def processPatientListInput(self):
        """
        Convert patient list input to a TSV file.
        """
        if self.patientListInput is None:
            raise ValueError("FeatureMatrixFactory.patientListInput is None.")

        if isinstance(self.patientListInput, cursor):
            return self._processPatientListDbCursor()
        elif isinstance(self.patientListInput, file):
            return self._processPatientListTsvFile()

    def _processPatientListDbCursor(self):
        """
        Convert self.patientListInput from DB cursor to TSV file.
        """
        patientListTempFile = open(self._patientListTempFileName, "w")
        self._pipeDbCursorToTsvFile(self.patientListInput, patientListTempFile)
        patientListTempFile.close()

    def _pipeDbCursorToTsvFile(self, dbCursor, tsvFile):
        """
        Pipe any arbitrary DB cursor to a TSV file.
        """
        # Extract DB columns.
        columns = dbCursor.description
        numColumns = len(columns)

        # Write TSV header.
        for i in range(numColumns - 1):
            # 0th index is column name.
            tsvFile.write("%s\t" % columns[i][0])
        tsvFile.write("%s\n" % columns[numColumns - 1][0])

        # By default, cursor iterates through both header and data rows.
        row = dbCursor.fetchone()
        while row is not None:
            for i in range(numColumns - 1):
                tsvFile.write("%s\t" % row[i])
            tsvFile.write("%s\n" % row[numColumns - 1])
            row = dbCursor.fetchone()

    def _processPatientListTsvFile(self):
        """
        Convert self.patientListInput from DB cursor to TSV file.
        """
        # Instantiate patientListTempFile.
        patientListTempFile = open(self._patientListTempFileName, "w")
        patientListTempFile.write("%s\n" % self.patientIdColumn)

        # Iterate through all rows in TSV file.
        # Extract patientId from dictionary.
        for row in TabDictReader(self.patientListInput):
            patientId = int(row[self.patientIdColumn])
            patientListTempFile.write("%s\n" % patientId)

        patientListTempFile.close()

    def getPatientListIterator(self):
        """
        Return TabDictReader for reading processed patient list.
        """
        return TabDictReader(open(self._patientListTempFileName, "r"))

    def setPatientEpisodeInput(self, patientEpisodeInput, \
        patientIdColumn = "patient_id", timestampColumn = "item_date"):
        """
        Define the input patient episode list for the feature matrix.
        patientEpisodeInput: TSV file descriptor or DB cursor.
        patientIdColumn: Name of TSV column or DB column.
        timestampColumn: Name of TSV column or DB column.
        """
        # Verify patientEpisodeInput is TSV file or DB cursor.
        if not isinstance(patientEpisodeInput, cursor) and \
            not isinstance(patientEpisodeInput, file):
            raise TypeError("patientEpisodeInput must be DB cursor or TSV file.")

        self.patientEpisodeInput = patientEpisodeInput
        self.patientEpisodeIdColumn = patientIdColumn
        self.patientEpisodeTimeColumn = timestampColumn

    def processPatientEpisodeInput(self):
        """
        Convert patient episode input to a TSV file.
        """
        if self.patientEpisodeInput is None:
            raise ValueError("FeatureMatrixFactory.patientEpisodeInput is None.")

        if isinstance(self.patientEpisodeInput, cursor):
            return self._processPatientEpisodeDbCursor()
        elif isinstance(self.patientEpisodeInput, file):
            return self._processPatientEpisodeTsvFile()



    def _processPatientEpisodeDbCursor(self):
        """
        Convert self.patientEpisodeInput from DB cursor to TSV file.
        """
        # Instantiate patientEpisodeTempFile.
        patientEpisodeTempFile = open(self._patientEpisodeTempFileName, "w")
        self._pipeDbCursorToTsvFile(self.patientEpisodeInput, patientEpisodeTempFile)
        patientEpisodeTempFile.close()
        self.patientsProcessed = True

    def _processPatientEpisodeTsvFile(self):
        pass

    def getPatientEpisodeIterator(self):
        """
        Return TabDictReader for reading processed patient episodes.
        """
        return TabDictReader(open(self._patientEpisodeTempFileName, "r"))

    def _getPatientEpisodeByIndexTimeById(self):
        """
        Return dictionary containing patientId : episodeTime : {} map.
        """
        patientEpisodeByIndexTimeById = {}
        patientEpisodeIterator = getPatientEpisodeIterator()

        for episode in patientEpisodeIterator:
            patientId = int(episode[self.patientEpisodeIdColumn])
            episodeTime = DBUtil.parseDateValue(episode[self.patientEpisodeTimeColumn])

            if patientId not in patientEpisodeByIndexTimeById:
                patientEpisodeByIndexTimeById[patientId] = {episodeTime: {}}
            else if episodeTime not in patientEpisodeByIndexTimeById[patientId]:
                patientEpisodeByIndexTimeById[patientId][episodeTime] = {}

        return patientEpisodeByIndexTimeById

    def addClinicalItemFeatures(self, clinicalItemNames, dayBins=None):
        """
        Query patient_item for the clinical item orders and results for each
        patient, and aggregate by episode timestamp.


        """
        # Verify patient list and/or patient episode has been processed.
        if not self.patientsProcessed:
            raise ValueError("Must process patients before clinical item.")

        clinicalItemEvents = self._queryClinicalItemsByName(clinicalItemNames)
        itemTimesByPatientId = self._getItemTimesByPatientId(clinicalItemEvents)

        # Read clinical item features to temp file.
        patientEpisodes = self.getPatientEpisodeIterator()
        self._processClinicalItemEvents(patientEpisodes, itemTimesByPatientId, \
                                        clinicalItemNames, dayBins)

    def _queryClinicalItemsByName(self, clinicalItemNames):
        """
        Query clinicalItemInput for all item times for all patients.

        Look for clinical items by name.
        Will match by SQL "LIKE" so can use wild-cards,
        or can use ~* operator for additional regular expression matching.
        """
        # Verify patient list and/or patient episode has been processed.
        if not self.patientsProcessed:
            raise ValueError("Must process patients before clinical item.")

        clinicalItemIds = None

        # If possible, return cached results.
        cacheKey = str(clinicalItemNames)
        if self.dbCache is not None and cacheKey in self.dbCache:
            clinicalItemIds = self.dbCache[cacheKey]
        else:
            column = "name"
            operator = "LIKE"

            query = SQLQuery()
            query.addSelect("clinical_item_id")
            query.addFrom("clinical_item")

            nameClauses = list()
            for itemName in clinicalItemNames:
                nameClauses.append("%s %s %%s" % (column, operator))
                query.params.append(itemName)
            query.addWhere(str.join(" or ", nameClauses))

            results = DBUtil.execute(query)
            clinicalItemIds = [row[0] for row in results]

        if len(clinicalItemIds) == 0:
            return list()

        return self.queryClinicalItems(clinicalItemIds)

    def queryClinicalItems(self, clinicalItemIds):
        """
        Query for all patient items that match with the given clinical item IDs.
        """
        # Identify which columns to pull from patient_item table.
        self._patientItemIdColumn = "patient_id"
        self._patientItemTimeColumn = "item_date"

        # Identify which patients to query.
        patientIds = set()
        patientEpisodes = self.getPatientEpisodeIterator()
        for episode in patientEpisodes:
            patientIds.add(episode[self.patientEpisodeIdColumn])

        # Construct query to pull from patient_item table.
        query = SQLQuery()
        query.addSelect(self._patientItemIdColumn)
        query.addSelect(self._patientItemTimeColumn)
        query.addFrom("patient_item")
        query.addWhereIn("clinical_item_id", clinicalItemIds)
        query.addWhereIn("patient_id", list(patientIds))
        query.addOrderBy("patient_id")
        query.addOrderBy("item_date")

        # Query clinical items.
        results = DBUtil.execute(query)
        clinicalItemEvents = [row for row in results]
        return clinicalItemEvents

    def _processClinicalItemEvents(self, patientEpisodes, itemTimesByPatientId, clinicalItemNames, dayBins):
        """
        Convert temp file containing all (patient_item, item_date) pairs
        for a given set of clinical_item_ids into temp file containing
        patient_id, order_time, clinical_item.pre, clinical_item.post, etc.
        """
        if len(clinicalItemNames) > 1:
            itemLabel = "-".join([itemName for itemName in clinicalItemNames])
        else:
            itemLabel = clinicalItemNames[0]
        tempFileName = self._patientItemTempFileNameFormat % itemLabel
        tempFile = open(tempFileName, "w")

        # Determine time buckets for clinical item times.
        if dayBins is None:
            dayBins = DELTA_NAME_BY_DAYS.keys()
            dayBins.sort();

        # Find items most proximate before and after the index item per patient
        # Record timedelta separating nearest items found from index item
        # Count up total items found before, after, and within days time bins
        preTimeDaysLabel = "%s.preTimeDays" % itemLabel
        postTimeDaysLabel = "%s.postTimeDays" % itemLabel
        preLabel = "%s.pre" % itemLabel
        postLabel = "%s.post" % itemLabel

        # Write header fields to tempFile.
        tempFile.write("patient_id\tepisode_time\t")
        tempFile.write("%s\t" % preTimeDaysLabel)
        tempFile.write("%s\t" % preLabel)
        tempFile.write("\t".join("%s.%dd" % (preLabel, dayBin) for dayBin in dayBins))
        tempFile.write("\t")
        tempFile.write("%s\t" % postTimeDaysLabel)
        tempFile.write("%s\t" % postLabel)
        tempFile.write("\t".join("%s.%dd" % (postLabel, dayBin) for dayBin in dayBins))
        tempFile.write("\n")

        # Write patient episode data to tempFile.
        for patientEpisode in patientEpisodes:
            # Initialize data to write to tempFile for patientEpisode.
            episodeData = {}
            patientId = int(patientEpisode[self.patientEpisodeIdColumn])
            episodeTime = DBUtil.parseDateValue(patientEpisode[self.patientEpisodeTimeColumn])
            # Time delta between index time and most closest past item event.
            episodeData[preTimeDaysLabel] = None
            # Time delta between index time and most closest future item event.
            episodeData[postTimeDaysLabel] = None
            # Number of item events before index time.
            episodeData[preLabel] = 0
            # Number of item events after index time.
            episodeData[postLabel] = 0
            # Number of item events within dayBin.
            for dayBin in dayBins:
                episodeData["%s.%dd" % (preLabel, dayBin)] = 0
                episodeData["%s.%dd" % (postLabel, dayBin)] = 0

            # Aggregate item events by day buckets.
            if patientId in itemTimesByPatientId:
                itemTimes = itemTimesByPatientId[patientId]
                if itemTimes is not None:
                    for itemTime in itemTimes:
                        timeDiffSeconds = (itemTime - episodeTime).total_seconds()
                        timeDiffDays = timeDiffSeconds / SECONDS_PER_DAY
                        # If event occurred before index time...
                        if timeDiffDays < 0:
                            if episodeData[preTimeDaysLabel] is None:
                                episodeData[preTimeDaysLabel] = timeDiffDays
                            elif abs(timeDiffDays) < abs(episodeData[preTimeDaysLabel]):
                                # Found more recent item event
                                episodeData[preTimeDaysLabel] = timeDiffDays
                            episodeData[preLabel] += 1
                            for dayBin in daysBins:
                                if abs(timeDiffDays) <= dayBin:
                                    episodeData["%s.%dd" % (preLabel, dayBin)] += 1
                        # Event occurred after index time...
                        else:
                            if episodeData[postTimeDaysLabel] is None:
                                episodeData[postTimeDaysLabel] = timeDiffDays
                            elif abs(timeDiffDays) < abs(episodeData[postTimeDaysLabel]):
                                # Found more proximate future event
                                episodeData[postTimeDaysLabel] = timeDiffDays
                            episodeData[postLabel] += 1
                            for dayBin in dayBins:
                                if abs(timeDiffDays) <= dayBin:
                                    episodeData["%s.%dd" % (postLabel, dayBin)] += 1

            # Write data to tempFile.
            tempFile.write("%s\t%s\t" % (patientId, episodeTime))
            tempFile.write("%s\t" % episodeData[preTimeDaysLabel])
            tempFile.write("%s\t" % episodeData[preLabel])
            tempFile.write("\t".join([str(episodeData["%s.%dd" % (preLabel, dayBin)]) for dayBin in dayBins]))
            tempFile.write("\t")
            tempFile.write("%s\t" % episodeData[postTimeDaysLabel])
            tempFile.write("%s\t" % episodeData[postLabel])
            tempFile.write("\t".join([str(episodeData["%s.%dd" % (postLabel, dayBin)]) for dayBin in dayBins]))
            tempFile.write("\n")

        tempFile.close()
        # Add tempFileName to list of feature temp files.
        self._featureTempFileNames.append(tempFileName)

    def addLabResultFeatures(self, labBaseNames):
        """
        Query stride_order_proc and stride_order_results for the lab orders and
        results for each patient, and aggregate by episode timestamp.
        """
        # Verify patient list and/or patient episode has been processed.
        if not self.patientsProcessed:
            raise ValueError("Must process patients before lab result.")

        labResults = self._queryLabResultsByName(labBaseNames)
        resultsByNameByPatientId = self._parseResultsData(labResults, "pat_id",
            "base_name", "ord_num_value", "result_time")

        # Read lab result features to temp file.
        patientEpisodeByIndexTimeById = self._getPatientEpisodeByIndexTimeById()
        self._processResultEvents(patientEpisodeByIndexTimeById,
                                    resultsByNameByPatientId,
                                    labBaseNames, valueCol, datetimeCol,
                                    preTimeDelta, postTimeDelta)
        patientEpisodes = self.getPatientEpisodeIterator()
        preTimeDays = None
        if preTimeDelta is not None:
            preTimeDays = preTimeDelta.days
        postTimeDays = None
        if postTimeDelta is not None:
            postTimeDays = postTimeDelta.days

        for episode in patientEpisodes:
            patientId = episode[self.patientEpisodeIdColumn]
            indexTime = episode[self.patientEpisodeTimeColumn]
            columnNames = self.colsFromBaseNames(baseNames, preTimeDays, postTimeDays)

        # TODO(sbala): Complete implementation based on addResultFeatures

    def colsFromBaseNames(self, baseNames, preTimeDays, postTimeDays):
        """Enumerate derived column/feature names given a set of (lab) result base names"""
        suffixes = ["count","countInRange","min","max","median","mean","std","first","last","diff","slope","proximate","firstTimeDays","lastTimeDays","proximateTimeDays"];
        for baseName in baseNames:
            for suffix in suffixes:
                colName = "%s.%s_%s.%s" % (baseName, preTimeDays, postTimeDays, suffix)
                yield colName

    def _processResultEvents(patientEpisodeByIndexTimeById, resultsByNameByPatientId, resultNames):
        """
        Add on summary features to the patient-time instances.
        With respect to each index time, look for results within
        [indexTime+preTimeDelta, indexTime+postTimeDelta) and
        generate summary features like count, mean, median, std, first, last,
        proximate. Generic function, so have to specify the names of the value
        and datetime columns.

        Assume patientIdResultsByNameGenerator is actually a generator for each
        patient, so can only stream through results once.

        Store results in a temp file.
        """
        if len(resultNames) > 1:
            resultLabel = "-".join([resultName for resultName in resultNames])
        else:
            resultLabel = resultNames[0]
        tempFileName = self._patientItemTempFileNameFormat % resultLabel
        tempFile = open(tempFileName, "w")

        # Use results generator as outer loop as will not be able to random
        # access the contents.
        for patientId, resultsByName in patientIdResultsByNameGenerator:
            # Skip results if not in our list of patients of interest
            if patientId in patientEpisodeByIndexTimeById:
                patientEpisodeByIndexTime = patientEpisodeByIndexTimeById[patientId]
                resultsByName = resultsByNameByPatientId[patientId]
                self._addResultFeatures_singleEpisode(patientEpisodeByIndexTime, \
                    resultsByName, baseNames, valueCol, datetimeCol, preTimeDelta, \
                    postTimeDelta)

        # Separate loop to verify all patient records addressed, even if no
        # results available (like an outer join).
        resultsByName = None
        for patientId, patientEpisodeByIndexTime in patientEpisodeByIndexTimeById.iteritems():
            self._addResultFeatures_singleEpisode(patientEpisodeByIndexTime, \
                resultsByName, baseNames, valueCol, datetimeCol, preTimeDelta, \
                postTimeDelta)


    def _addResultFeatures_singleEpisode(self, patientEpisodeByIndexTime, resultsByName, baseNames, valueCol, datetimeCol, preTimeDelta, postTimeDelta):
        """
        Add summary features to the patient-time instances.
        With respect to each index time, look for results within
        [indexTime+preTimeDelta, indexTime+postTimeDelta) and generate summary
        features like count, mean, median, std, first, last, proximate.
        Generic function, so have to specify the names of the value and datetime columns to look for.

        If resultsByName is None, then no results to match.
        Just make sure default / zero value columns are populated if
        they are not already.
        """
        preTimeDays = None
        if preTimeDelta is not None:
            preTimeDays = pretimeDelta.days
        postTimeDays = None
        if postTimeDelta is not None:
            postTimeDays = postTimeDelta.days

        # Init summary values to null for all results
        for indexTime, patient in patientEpisodeByIndexTime.iteritems():
            for baseName in baseNames:
                if resultsByName is not None or ("%s.%s_%s.count" % (baseName, preTimeDays, postTimeDays)) not in patient:
                    # Default to null for all values
                    patient["%s.%s_%s.count" % (baseName,preTimeDays,postTimeDays)] = 0
                    patient["%s.%s_%s.countInRange" % (baseName,preTimeDays,postTimeDays)] = 0
                    patient["%s.%s_%s.min" % (baseName,preTimeDays,postTimeDays)] = None
                    patient["%s.%s_%s.max" % (baseName,preTimeDays,postTimeDays)] = None
                    patient["%s.%s_%s.median" % (baseName,preTimeDays,postTimeDays)] = None
                    patient["%s.%s_%s.mean" % (baseName,preTimeDays,postTimeDays)] = None
                    patient["%s.%s_%s.std" % (baseName,preTimeDays,postTimeDays)] = None
                    patient["%s.%s_%s.first" % (baseName,preTimeDays,postTimeDays)] = None
                    patient["%s.%s_%s.last" % (baseName,preTimeDays,postTimeDays)] = None
                    patient["%s.%s_%s.diff" % (baseName,preTimeDays,postTimeDays)] = None
                    patient["%s.%s_%s.slope" % (baseName,preTimeDays,postTimeDays)] = None
                    patient["%s.%s_%s.proximate" % (baseName,preTimeDays,postTimeDays)] = None
                    patient["%s.%s_%s.firstTimeDays" % (baseName,preTimeDays,postTimeDays)] = None
                    patient["%s.%s_%s.lastTimeDays" % (baseName,preTimeDays,postTimeDays)] = None
                    patient["%s.%s_%s.proximateTimeDays" % (baseName,preTimeDays,postTimeDays)] = None

        # Have results available for this patient?
        if resultsByName is not None:
            for indexTime, patient in patientEpisodeByIndexTime.iteritems():
                # Time range limits on labs to consider
                if preTimeDelta is not None:
                    preTimeLimit = indexTime + preTimeDelta
                if postTimeDelta is not None:
                    postTimeLimit = indexTime + postTimeDelta

            for baseName in baseNames:
                proximateValue = None
                # Not all patients will have all labs checked
                if resultsByName is not None and basename in resultsByName:
                    firstItem = None
                    lastItem = None
                    # Item closest to the index time in time
                    proximateItem = None
                    filteredResults = list()
                    for result in resultsByName[baseName]:
                        resultTime = result[datetimeCol]
                        if (preTimeLimit is None or preTimeLimit <= resultTime) \
                            and (postTimeLimit is None or resultTime < postTimeLimit):
                            # Occurs within timeframe of interest, so record valueCol
                            filteredResults.append(result)

                            if firstItem is None or resultTime < firstItem[datetimeCol]:
                                firstItem = result
                            if lastItem is None or lastItem[datetimeCol] < resultTime:
                                lastTime = result
                            if proximateItem is None or (abs(result - indexTime) < abs(proximateItem[datetimeCol] - indexTime)):
                                proximateItem = result

                    if len(filteredResults) > 0:
                        # Count up number of values specifically labeled "in range"
                        valueList = columnFromModelList(filteredResults, valueCol)
                        patient["%s.%s_%s.count" % (baseName,preTimeDays,postTimeDays)] = len(valueList);
                        patient["%s.%s_%s.countInRange" % (baseName,preTimeDays,postTimeDays)] = self.countResultsInRange(filteredResults);
                        patient["%s.%s_%s.min" % (baseName,preTimeDays,postTimeDays)] = np.min(valueList);
                        patient["%s.%s_%s.max" % (baseName,preTimeDays,postTimeDays)] = np.max(valueList);
                        patient["%s.%s_%s.median" % (baseName,preTimeDays,postTimeDays)] = np.median(valueList);
                        patient["%s.%s_%s.mean" % (baseName,preTimeDays,postTimeDays)] = np.mean(valueList);
                        patient["%s.%s_%s.std" % (baseName,preTimeDays,postTimeDays)] = np.std(valueList);
                        patient["%s.%s_%s.first" % (baseName,preTimeDays,postTimeDays)] = firstItem[valueCol];
                        patient["%s.%s_%s.last" % (baseName,preTimeDays,postTimeDays)] = lastItem[valueCol];
                        patient["%s.%s_%s.diff" % (baseName,preTimeDays,postTimeDays)] = lastItem[valueCol] - firstItem[valueCol];
                        patient["%s.%s_%s.slope" % (baseName,preTimeDays,postTimeDays)] = 0.0;
                        timeDiffDays = ((lastItem[datetimeCol]-firstItem[datetimeCol]).total_seconds() / SECONDS_PER_DAY);
                        if timeDiffDays > 0.0:
                            patient["%s.%s_%s.slope" % (baseName,preTimeDays,postTimeDays)] = (lastItem[valueCol]-firstItem[valueCol]) / timeDiffDays;
                        patient["%s.%s_%s.proximate" % (baseName,preTimeDays,postTimeDays)] = proximateItem[valueCol];
                        patient["%s.%s_%s.firstTimeDays" % (baseName,preTimeDays,postTimeDays)] = (firstItem[datetimeCol]-indexTime).total_seconds() / SECONDS_PER_DAY;
                        patient["%s.%s_%s.lastTimeDays" % (baseName,preTimeDays,postTimeDays)] = (lastItem[datetimeCol]-indexTime).total_seconds() / SECONDS_PER_DAY;
                        patient["%s.%s_%s.proximateTimeDays" % (baseName,preTimeDays,postTimeDays)] = (proximateItem[datetimeCol]-indexTime).total_seconds() / SECONDS_PER_DAY;

        return

    def _queryLabResultsByName(self, labBaseNames):
        """
        Query for all lab results that match with the given result base names.
        """
        # Verify patient list and/or patient episode has been processed.
        if not self.patientsProcessed:
            raise ValueError("Must process patients before lab results.")

        # Query rapid when filter by lab result type, limited to X records.
        # Filtering by patient ID drags down substantially until preloaded
        # table by doing a count on the SQR table?
        columnNames = [
            "CAST(pat_id AS bigint)", "base_name", "ord_num_value",
            "result_flag", "result_in_range_yn", "sor.result_time"
        ]

        # Identify which patients to query.
        patientIds = set()
        patientEpisodes = self.getPatientEpisodeIterator()
        for episode in patientEpisodes:
            patientIds.add(episode[self.patientEpisodeIdColumn])

        # Construct query to pull from stride_order_results, stride_order_proc
        query = SQLQuery()
        for column in columnNames:
            query.addSelect(column)
        query.addFrom("stride_order_results AS sor, stride_order_proc AS sop")
        query.addWhere("sor.order_proc_id = sop.order_proc_id")
        query.addWhereIn("base_name", labBaseNames)
        query.addWhereIn("pat_id", patientIds)
        query.addOrderBy("pat_id")
        query.addOrderBy("sor.result_time")

        results = DBUtil.execute(query)
        return results

    def _parseResultsData(self, resultRowIter, patientIdCol, nameCol, valueCol, datetimeCol):
        """
        Wrapper for generator version to translate results into dictionary by
        patient ID for more consistent structure to parseClinicalItemData.
        """
        resultsByNameByPatientId = dict()
        for (patientId, resultsByName) in self.parseResultsDataGenerator(resultRowIter, patientIdCol, nameCol, valueCol, datetimeCol)
            resultsByNameByPatientId[patientId] = resultsByName
        return resultsByNameByPatientId

    def _parseResultsDataGenerator(self, resultRowIter, patientIdCol, nameCol, valueCol, datetimeCol):
        """
        General version of results data parser, which does not necessarily come
        from a file stream. Could be any reader / iterator over rows of item
        data. For example, from a TabDictReader over the temp file or
        modelListFromTable from database query results.
        """
        lastPatientId = None
        resultsByName = None
        for result in resultRowIter:
            if result[valueCol] is not None and result[valueCol] != NULL_STRING:
                patientId = int(result[patientIdCol])
                baseName = result[nameCol]
                resultValue = float(result[valueCol])
                resultTime = DBUtil.parseDateValue(result[datetimeCol])

                # Skip apparent placeholder values
                if resultValue < SENTINEL_RESULT_VALUE:
                    result[patientIdCol] = result["patient_id"] = patientIdCol
                    result[valueCol] = resultValue
                    result[datetimeCol] = resultTime

                    if patientId != lastPatientId:
                        # Encountering a new patient ID. Yield the results from
                        # the prior one before preparing for next one.
                        if lastPatientId is not None:
                            yield (lastPatientId, resultsByName)
                        lastPatientId = patientId
                        resultsByName = dict()
                    if baseName not in resultsByName:
                        resultsByName[baseName] = list()
                    resultsByName[baseName].append(result)

        # Yield last result
        if lastPatientId is not None:
            yield (lastPatientId, resultsByName)

    def _getItemTimesByPatientId(self, clinicalItemEvents):
        """
        input: [{"patient_id":123, "item_date": 456}, ...]
        output: {123 : [456, 789]}
        """
        itemTimesByPatientId = dict()

        for itemData in clinicalItemEvents:
            # Convert patient_id to int and item_date to DBUtil.parseDateValue.
            # TODO(sbala): Stop relying on magic 0- and 1-indexes.
            patientId = int(itemData[0])
            itemTime = DBUtil.parseDateValue(itemData[1])
            itemData[0] = patientId
            itemData[1] = itemTime

            # Add item_date to itemTimesByPatientId
            if patientId not in itemTimesByPatientId:
                itemTimesByPatientId[patientId] = list()
            itemTimesByPatientId[patientId].append(itemTime)

        return itemTimesByPatientId

    def _readPatientEpisodesFile(self):
        """
        Read patient episodes into memory.
        """
        # Verify patient episodes have been processed.
        if not self.patientsProcessed:
            raise ValueError("Must process patient episodes before reading.")

        # Return iterator through _patientEpisodeTempFileName.
        iterator = TabDictReader(open(self._patientEpisodeTempFileName, "r"))
        patientEpisodes = [episode for episode in iterator]

        return patientEpisodes

    def processClinicalItemInput(self, clinicalItemName):
        """
        Process clinicalItemName for DB cursor.
        """
        patientEpisodes = self._readPatientEpisodesFile()
        pass

    def _queryClinicalItemInput():
        pass

    def _parseClinicalItems():
        pass

    def buildFeatureMatrix(self):
        """
        Given a set of factory inputs, build a feature matrix which
        can then be output.

        For each input, use the following idiom to process:
        self._processFooInput()
            self._queryFooInput()
            self._parseFooInput()
        """
        # Initialize feature matrix file.
        timestamp = datetime.datetime.now().strftime("%Y-%m-%d_%H.%M")
        matrixFileName = "feature-matrix_%s.tab" % timestamp
        matrixFile = open(matrixFileName, "w")
        self._matrixFileName = matrixFileName

        # Read arbitrary number of input temp files.
        # Use csv tab reader so we can just read the lists while being agnostic
        # to the actual fields in each of the various files.
        tempFiles = list()
        tempFileReaders = list()
        patientEpisodeFile = open(self._patientEpisodeTempFileName, "r")
        patientEpisodeReader = csv.reader(patientEpisodeFile, delimiter="\t")

        for tempFileName in self._featureTempFileNames:
            tempFile = open(tempFileName, "r")
            tempFileReader = csv.reader(tempFile, delimiter="\t")
            tempFiles.append(tempFile)
            tempFileReaders.append(tempFileReader)

        # Write data to matrix file.
        for patientEpisode in patientEpisodeReader:
            matrixData = list()
            # Add data from patientEpisodes.
            matrixData.extend(patientEpisode)
            # Each tempFile has the patientId and episodeTime fields.
            # Don't write these to the matrix file.
            for tempFileReader in tempFileReaders:
                tempData = tempFileReader.next()
                matrixData.extend(tempData[2:])

            # Write data to matrixFile, with trailing \n.
            matrixFile.write("\t".join(matrixData))
            matrixFile.write("\n")

        # Close temp files.
        [tempFile.close() for tempFile in tempFiles]
        # Clean up temp files.
        for tempFileName in self._featureTempFileNames:
            try:
                os.remove(tempFileName)
            except OSError:
                pass

    def _getMatrixIterator(self):
        return TabDictReader(open(self._matrixFileName, "r"))

    def readFeatureMatrixFile(self):
        reader = csv.reader(open(self._matrixFileName, "r"), delimiter="\t")
        # reader = self._getMatrixIterator()
        featureMatrixData = [episode for episode in reader]

        return featureMatrixData