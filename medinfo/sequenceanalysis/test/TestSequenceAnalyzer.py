import datetime
import numpy as np
import unittest
from collections import defaultdict

from medinfo.sequenceanalysis.SequenceAnalyzer import SequenceAnalyzer

class TestSequenceAnalyzer(unittest.TestCase):

  def setUp(self):
    """Prepare state for test cases"""
    pass

  def tearDown(self):
    """Restore state from any setUp or test steps"""
    pass

  def testSequenceAnalyzerBulk(self):
    """Lab test counting normal and abnormal consecutive lab tests"""
    data = [
      ('11210R', [
        [-11380099600907, '11210R(InRange)', datetime.datetime(2012, 9, 10, 7, 25)],
        [-11380099600907, '11210R(InRange)', datetime.datetime(2012, 9, 24, 9, 24)],
        [-10226028839621, '11210R(Result)', datetime.datetime(2012, 3, 16, 14, 24)],
        [-10226028839621, '11210R(InRange)', datetime.datetime(2012, 3, 24, 8, 2)],
        [-9834093246550, '11210R(Result)', datetime.datetime(2013, 10, 1, 15, 24)],
        [-9834093246550, '11210R(InRange)', datetime.datetime(2013, 10, 9, 7, 10)],
        [-8443896915633, '11210R(InRange)', datetime.datetime(2013, 5, 1, 6, 55)],
        [-8443896915633, '11210R(InRange)', datetime.datetime(2013, 5, 5, 8, 5)],
        [-5023114876861, '11210R(InRange)', datetime.datetime(2011, 10, 16, 13, 37)],
        [-5023114876861, '11210R(InRange)', datetime.datetime(2011, 10, 20, 15, 25)],
        [-4423981885898, '11210R(InRange)', datetime.datetime(2012, 11, 17, 8, 11)],
        [-4423981885898, '11210R(InRange)', datetime.datetime(2012, 11, 25, 9, 29)],
        [-3908850479087, '11210R(InRange)', datetime.datetime(2010, 9, 9, 16, 43)],
        [-3908850479087, '11210R(InRange)', datetime.datetime(2010, 9, 13, 15, 11)],
        [-1872296128547, '11210R(Result)', datetime.datetime(2013, 12, 1, 21, 39)],
        [-1872296128547, '11210R(InRange)', datetime.datetime(2013, 12, 10, 13, 34)],
        [-1378995679303, '11210R(Result)', datetime.datetime(2010, 3, 9, 14, 17)],
        [-1378995679303, '11210R(InRange)', datetime.datetime(2010, 3, 11, 9, 31)],
        [8662609401678, '11210R(InRange)', datetime.datetime(2012, 7, 6, 12, 19)],
        [8662609401678, '11210R(InRange)', datetime.datetime(2012, 7, 11, 8, 48)],
        [8848376950672, '11210R(Result)', datetime.datetime(2013, 10, 30, 14, 56)],
        [8848376950672, '11210R(InRange)', datetime.datetime(2013, 11, 6, 6, 50)],
        [9472424502184, '11210R(InRange)', datetime.datetime(2011, 1, 13, 6, 55)],
        [9472424502184, '11210R(InRange)', datetime.datetime(2013, 2, 2, 9, 40)],
        [9592401025493, '11210R(Result)', datetime.datetime(2013, 1, 29, 1, 3)],
        [9592401025493, '11210R(InRange)', datetime.datetime(2013, 2, 11, 9, 1)],
        [9924214318080, '11210R(Result)', datetime.datetime(2012, 6, 8, 8, 32)],
        [9924214318080, '11210R(InRange)', datetime.datetime(2012, 6, 16, 10, 20)],
        [11286739503688, '11210R(InRange)', datetime.datetime(2011, 8, 10, 13, 56)],
        [11286739503688, '11210R(High)', datetime.datetime(2011, 11, 19, 12, 23)]
      ]),
      ('11211R', [
        [-11380099600907, '11211R(InRange)', datetime.datetime(2012, 9, 10, 7, 25)],
        [-11380099600907, '11211R(InRange)', datetime.datetime(2012, 9, 24, 9, 24)],
        [-10226028839621, '11211R(Result)', datetime.datetime(2012, 3, 16, 14, 24)],
        [-10226028839621, '11211R(InRange)', datetime.datetime(2012, 3, 24, 8, 2)],
        [-9834093246550, '11211R(Result)', datetime.datetime(2013, 10, 1, 15, 24)],
        [-9834093246550, '11211R(InRange)', datetime.datetime(2013, 10, 9, 7, 10)],
        [-8443896915633, '11211R(InRange)', datetime.datetime(2013, 5, 1, 6, 55)],
        [-8443896915633, '11211R(InRange)', datetime.datetime(2013, 5, 5, 8, 5)],
        [-5023114876861, '11211R(InRange)', datetime.datetime(2011, 10, 16, 13, 37)],
        [-5023114876861, '11211R(InRange)', datetime.datetime(2011, 10, 20, 15, 25)],
        [-4423981885898, '11211R(InRange)', datetime.datetime(2012, 11, 17, 8, 11)],
        [-4423981885898, '11211R(InRange)', datetime.datetime(2012, 11, 25, 9, 29)],
        [-3908850479087, '11211R(InRange)', datetime.datetime(2010, 9, 9, 16, 43)],
        [-3908850479087, '11211R(InRange)', datetime.datetime(2010, 9, 13, 15, 11)],
        [-1872296128547, '11211R(Result)', datetime.datetime(2013, 12, 1, 21, 39)],
        [-1872296128547, '11211R(InRange)', datetime.datetime(2013, 12, 10, 13, 34)],
        [-1378995679303, '11211R(Result)', datetime.datetime(2010, 3, 9, 14, 17)],
        [-1378995679303, '11211R(InRange)', datetime.datetime(2010, 3, 11, 9, 31)],
        [8662609401678, '11211R(InRange)', datetime.datetime(2012, 7, 6, 12, 19)],
        [8662609401678, '11211R(InRange)', datetime.datetime(2012, 7, 11, 8, 48)],
        [8848376950672, '11211R(Result)', datetime.datetime(2013, 10, 30, 14, 56)],
        [8848376950672, '11211R(InRange)', datetime.datetime(2013, 11, 6, 6, 50)],
        [9472424502184, '11211R(InRange)', datetime.datetime(2011, 1, 13, 6, 55)],
        [9472424502184, '11211R(InRange)', datetime.datetime(2013, 2, 2, 9, 40)],
        [9592401025493, '11211R(Result)', datetime.datetime(2013, 1, 29, 1, 3)],
        [9592401025493, '11211R(InRange)', datetime.datetime(2013, 2, 11, 9, 1)],
        [9924214318080, '11211R(Result)', datetime.datetime(2012, 6, 8, 8, 32)],
        [9924214318080, '11211R(InRange)', datetime.datetime(2012, 6, 16, 10, 20)],
        [11286739503688, '11211R(InRange)', datetime.datetime(2011, 8, 10, 13, 56)],
        [11286739503688, '11211R(InRange)', datetime.datetime(2011, 11, 19, 12, 23)]
      ]),
      ('11212R', [
        [-11380099600907, '11212R(InRange)', datetime.datetime(2012, 9, 10, 7, 25)],
        [-11380099600907, '11212R(InRange)', datetime.datetime(2012, 9, 24, 9, 24)],
        [-10226028839621, '11212R(Result)', datetime.datetime(2012, 3, 16, 14, 24)],
        [-10226028839621, '11212R(InRange)', datetime.datetime(2012, 3, 24, 8, 2)],
        [-9834093246550, '11212R(Result)', datetime.datetime(2013, 10, 1, 15, 24)],
        [-9834093246550, '11212R(InRange)', datetime.datetime(2013, 10, 9, 7, 10)],
        [-8443896915633, '11212R(InRange)', datetime.datetime(2013, 5, 1, 6, 55)],
        [-8443896915633, '11212R(InRange)', datetime.datetime(2013, 5, 5, 8, 5)],
        [-5023114876861, '11212R(InRange)', datetime.datetime(2011, 10, 16, 13, 37)],
        [-5023114876861, '11212R(InRange)', datetime.datetime(2011, 10, 20, 15, 25)],
        [-4423981885898, '11212R(InRange)', datetime.datetime(2012, 11, 17, 8, 11)],
        [-4423981885898, '11212R(InRange)', datetime.datetime(2012, 11, 25, 9, 29)],
        [-3908850479087, '11212R(InRange)', datetime.datetime(2010, 9, 9, 16, 43)],
        [-3908850479087, '11212R(InRange)', datetime.datetime(2010, 9, 13, 15, 11)],
        [-1872296128547, '11212R(Result)', datetime.datetime(2013, 12, 1, 21, 39)],
        [-1872296128547, '11212R(InRange)', datetime.datetime(2013, 12, 10, 13, 34)],
        [-1378995679303, '11212R(Result)', datetime.datetime(2010, 3, 9, 14, 17)],
        [-1378995679303, '11212R(InRange)', datetime.datetime(2010, 3, 11, 9, 31)],
        [8662609401678, '11212R(InRange)', datetime.datetime(2012, 7, 6, 12, 19)],
        [8662609401678, '11212R(InRange)', datetime.datetime(2012, 7, 11, 8, 48)],
        [8848376950672, '11212R(Result)', datetime.datetime(2013, 10, 30, 14, 56)],
        [8848376950672, '11212R(InRange)', datetime.datetime(2013, 11, 6, 6, 50)],
        [9472424502184, '11212R(High)', datetime.datetime(2011, 1, 13, 6, 55)],
        [9472424502184, '11212R(High)', datetime.datetime(2013, 2, 2, 9, 40)],
        [9592401025493, '11212R(Result)', datetime.datetime(2013, 1, 29, 1, 3)],
        [9592401025493, '11212R(InRange)', datetime.datetime(2013, 2, 11, 9, 1)],
        [9924214318080, '11212R(Result)', datetime.datetime(2012, 6, 8, 8, 32)],
        [9924214318080, '11212R(InRange)', datetime.datetime(2012, 6, 16, 10, 20)],
        [11286739503688, '11212R(InRange)', datetime.datetime(2011, 8, 10, 13, 56)],
        [11286739503688, '11212R(InRange)', datetime.datetime(2011, 11, 19, 12, 23)]
      ]),
      ('11213R', [
        [-11380099600907, '11213R(InRange)', datetime.datetime(2012, 9, 10, 7, 25)],
        [-11380099600907, '11213R(InRange)', datetime.datetime(2012, 9, 24, 9, 24)],
        [-10226028839621, '11213R(Result)', datetime.datetime(2012, 3, 16, 14, 24)],
        [-10226028839621, '11213R(InRange)', datetime.datetime(2012, 3, 24, 8, 2)],
        [-9834093246550, '11213R(Result)', datetime.datetime(2013, 10, 1, 15, 24)],
        [-9834093246550, '11213R(InRange)', datetime.datetime(2013, 10, 9, 7, 10)],
        [-8443896915633, '11213R(InRange)', datetime.datetime(2013, 5, 1, 6, 55)],
        [-8443896915633, '11213R(InRange)', datetime.datetime(2013, 5, 5, 8, 5)],
        [-5023114876861, '11213R(InRange)', datetime.datetime(2011, 10, 16, 13, 37)],
        [-5023114876861, '11213R(InRange)', datetime.datetime(2011, 10, 20, 15, 25)],
        [-4423981885898, '11213R(InRange)', datetime.datetime(2012, 11, 17, 8, 11)],
        [-4423981885898, '11213R(InRange)', datetime.datetime(2012, 11, 25, 9, 29)],
        [-3908850479087, '11213R(InRange)', datetime.datetime(2010, 9, 9, 16, 43)],
        [-3908850479087, '11213R(InRange)', datetime.datetime(2010, 9, 13, 15, 11)],
        [-1872296128547, '11213R(Result)', datetime.datetime(2013, 12, 1, 21, 39)],
        [-1872296128547, '11213R(High)', datetime.datetime(2013, 12, 10, 13, 34)],
        [-1378995679303, '11213R(Result)', datetime.datetime(2010, 3, 9, 14, 17)],
        [-1378995679303, '11213R(InRange)', datetime.datetime(2010, 3, 11, 9, 31)],
        [8662609401678, '11213R(InRange)', datetime.datetime(2012, 7, 6, 12, 19)],
        [8662609401678, '11213R(InRange)', datetime.datetime(2012, 7, 11, 8, 48)],
        [8848376950672, '11213R(Result)', datetime.datetime(2013, 10, 30, 14, 56)],
        [8848376950672, '11213R(InRange)', datetime.datetime(2013, 11, 6, 6, 50)],
        [9472424502184, '11213R(InRange)', datetime.datetime(2011, 1, 13, 6, 55)],
        [9472424502184, '11213R(InRange)', datetime.datetime(2013, 2, 2, 9, 40)],
        [9592401025493, '11213R(Result)', datetime.datetime(2013, 1, 29, 1, 3)],
        [9592401025493, '11213R(InRange)', datetime.datetime(2013, 2, 11, 9, 1)],
        [9924214318080, '11213R(Result)', datetime.datetime(2012, 6, 8, 8, 32)],
        [9924214318080, '11213R(InRange)', datetime.datetime(2012, 6, 16, 10, 20)],
        [11286739503688, '11213R(InRange)', datetime.datetime(2011, 8, 10, 13, 56)],
        [11286739503688, '11213R(InRange)', datetime.datetime(2011, 11, 19, 12, 23)]
      ])
    ]

    # Extract the patient_id from a row, where patient_id is in column 0
    def extract_patient_id_key_fn(row):
      return row[0]

    def handle_sentinel_queue_fn(window_size, vars_dict, sentinel, row):
      vars_dict['prior_history'] = bool(row[2] - sentinel[2] <= window_size)

    # After running filter/pop queue, if results in empty queue, then do stuff here (reset prior_history record having no prior records within window / as opposed to an abnormal value being present before)
    def emptied_queue_handler_fn(window_size, vars_dict, row):
      vars_dict['prior_history'] = False

    # Acts as the mapper of a map-reduce step, where the "reduce" is left up to the user
    def extract_key_value_fn(window_size, queue, vars_dict):
      if vars_dict['prior_history']:
        # if there is prior_history, set number_consecutive_normals as usual
        number_consecutive_normals = len(queue)
      else:
        # else set number_consecutive_normals as None
        number_consecutive_normals = None
      return (window_size.days, number_consecutive_normals), 1

    # Extract the datetime from a row, where datetime is in column 2
    def extract_datetime_fn(row):
      return row[2]

    # Column 1 of row is a string that contains the lab result
    def add_row_condition_fn(window_size, queue, vars_dict, row):
      return 'InRange' in row[1]

    def clear_queue_condition_fn(window_size, queue, vars_dict, row):
      return not vars_dict['row_added']

    sequence_analyzer = SequenceAnalyzer()

    # Basically doing split by patientId, assuming that patientId is the first column
    sequence_analyzer.split_data_on_key(extract_patient_id_key_fn)

    # Prior_history reflects whether something was previously in queue. Init vars allows pass in parameter dictionary
    sequence_analyzer.initialize_vars({'prior_history': False})

    # If queue is just a sentinel, this will evaluate. Example sentinel value: Cleared queue after every abnormal test, but still need to keep track of date of abnormal value
    # Check whether queue has a single sentinel value, but need some residual value (e.g., last date to allow maintenance of prior_history)
    sequence_analyzer.handle_sentinel_queue(handle_sentinel_queue_fn)

    # Pop queue criteria, for example to remove items from head of queue as progress
    sequence_analyzer.pop_queue(extract_datetime_fn, emptied_queue_handler_fn)

    sequence_analyzer.extract_key_value(extract_key_value_fn)

    sequence_analyzer.add_row(add_row_condition_fn)
    sequence_analyzer.clear_queue(clear_queue_condition_fn, add_sentinel=True)

    sequence_analyzer.set_var('prior_history', lambda window_size, queue, vars_dict, row: True)

    sequence_analyzer.build(2)

    global_stats = defaultdict(lambda: defaultdict(lambda: np.array([0, 0])))
    # window_sizes = [1, 2, 4, 7, 30, 90] # list of window sizes to evaluate
    window_sizes = [datetime.timedelta(days=size) for size in [1, 2, 4, 7, 30, 90]] # list of window sizes to evaluate

    for base_name, results in data:
      counts = defaultdict(lambda: np.array([0, 0]))
      for return_values in sequence_analyzer.run(results, window_sizes):
        (key, value), row_added = return_values
        counts[key][0] += value
        if row_added:
          counts[key][1] += value

      # switch (window_size, 0) to mean no priors,
      # and switch (window_size, None) to be the total count
      total_counts = defaultdict(lambda: np.array([0, 0]))
      for k, v in counts.items():
        # Aggregate total number of results and positive results
        total_counts[k[0]] += v
      for window_size in window_sizes:
        # Set (1, 0) to (1, None)
        counts[(window_size.days, 0)] = counts[(window_size.days, None)]
        # Set (window_size, None) to the sum of calculated above
        counts[(window_size.days, None)] = total_counts[window_size.days]

      for k, v in counts.items():
        global_stats[base_name][k] += v

    def normalize_dict(d):
      # flatten defaultdict and np.array types to dict and list
      normalized_d = {}
      for k1, v1 in d.items():
        normalized_d[k1] = {k2: list(v2) for k2, v2 in v1.items()}
      return normalized_d

    global_stats = normalize_dict(global_stats)

    expectedResults = {
      '11213R': {
        (90, None): [30, 22],
        (30, 1): [6, 6],
        (30, None): [30, 22],
        (7, None): [30, 22],
        (90, 1): [6, 6],
        (7, 1): [4, 4],
        (90, 0): [17, 10],
        (4, None): [30, 22],
        (30, 0): [17, 10],
        (1, None): [30, 22],
        (2, 0): [29, 21],
        (2, None): [30, 22],
        (7, 0): [24, 16],
        (1, 0): [30, 22],
        (4, 1): [1, 1],
        (4, 0): [28, 20]},
      '11210R': {
        (90, None): [30, 22],
        (30, 1): [6, 6],
        (30, None): [30, 22],
        (7, None): [30, 22],
        (90, 1): [6, 6],
        (7, 1): [4, 4],
        (90, 0): [17,  9],
        (4, None): [30, 22],
        (30, 0): [17,  9],
        (1, None): [30, 22],
        (2, 0): [29, 21],
        (2, None): [30, 22],
        (7, 0): [24, 16],
        (1, 0): [30, 22],
        (4, 1): [1, 1],
        (4, 0): [28, 20]},
      '11212R': {
        (90, None): [30, 21],
        (30, 1): [6, 6],
        (30, None): [30, 21],
        (7, None): [30, 21],
        (90, 1): [6, 6],
        (7, 1): [4, 4],
        (90, 0): [17,  8],
        (4, None): [30, 21],
        (30, 0): [17,  8],
        (1, None): [30, 21],
        (2, 0): [29, 20],
        (2, None): [30, 21],
        (7, 0): [24, 15],
        (1, 0): [30, 21],
        (4, 1): [1, 1],
        (4, 0): [28, 19]},
      '11211R': {
        (90, None): [30, 23],
        (30, 1): [6, 6],
        (30, None): [30, 23],
        (7, None): [30, 23],
        (90, 1): [6, 6],
        (7, 1): [4, 4],
        (90, 0): [17, 10],
        (4, None): [30, 23],
        (30, 0): [17, 10],
        (1, None): [30, 23],
        (2, 0): [29, 22],
        (2, None): [30, 23],
        (7, 0): [24, 17],
        (1, 0): [30, 23],
        (4, 1): [1, 1],
        (4, 0): [28, 21]}
      }
    self.assertEqual(expectedResults, global_stats)

def suite():
  """Returns the suite of tests to run for this test class / module.
  Use unittest.makeSuite methods which simply extracts all of the
  methods for the given class whose name starts with "test"
  """
  suite = unittest.TestSuite()
  suite.addTest(unittest.makeSuite(TestSequenceAnalyzer))
  return suite


if __name__ == "__main__":
  unittest.TextTestRunner(verbosity=2).run(suite())
