
# http://zurb.com/forrst/posts/Interval_Tree_implementation_in_python-e0K


class IntervalTree:
  def __init__(self, intervals):
    self.top_node = self.divide_intervals(intervals)

  def divide_intervals(self, intervals):

    if not intervals:
      return None

    x_center = self.center(intervals)

    s_center = []
    s_left = []
    s_right = []

    for k in intervals:
      if k.get_end() < x_center:
        s_left.append(k)
      elif k.get_begin() > x_center:
        s_right.append(k)
      else:
        s_center.append(k)

    return Node(x_center, s_center, self.divide_intervals(s_left), self.divide_intervals(s_right))


  def center(self, intervals):
    fs = sort_by_begin(intervals)
    length = len(fs)

    return fs[int(length/2)].get_begin()

  def search(self, begin, end=None):
    if end:
      result = []

      for j in xrange(begin, end+1):
        for k in self.search(j):
          result.append(k)
        result = list(set(result))
      return sort_by_begin(result)
    else:
      return self._search(self.top_node, begin, [])
  def _search(self, node, point, result):

    for k in node.s_center:
      if k.get_begin() <= point <= k.get_end():
        result.append(k)
    if point < node.x_center and node.left_node:
      for k in self._search(node.left_node, point, []):
        result.append(k)
    if point > node.x_center and node.right_node:
      for k in self._search(node.right_node, point, []):
        result.append(k)

    return list(set(result))

class Interval:
  def __init__(self, begin, end):
    self.begin = begin
    self.end = end

  def get_begin(self):
    return self.begin
  def get_end(self):
    return self.end

class Node:
  def __init__(self, x_center, s_center, left_node, right_node):
    self.x_center = x_center
    self.s_center = sort_by_begin(s_center)
    self.left_node = left_node
    self.right_node = right_node

def sort_by_begin(intervals):
  return sorted(intervals, key=lambda x: x.get_begin())

############################################################################################################
class ScheduleItem:
     def __init__(self, course_number, start_time, end_time):
         self.course_number = course_number
         self.start_time = start_time
         self.end_time = end_time
     def get_begin(self):
         return minutes_from_midnight(self.start_time)
     def get_end(self):
         return minutes_from_midnight(self.end_time)
     def __repr__(self):
         return ''.join(["{ScheduleItem: ", str((self.course_number, self.start_time, self.end_time)), "}"])
def minutes_from_midnight( hours ):
  return int( hours * 2 )

T = IntervalTree([ScheduleItem(28374, 9, 10), \
                 ScheduleItem(43564, 8, 12), \
                 ScheduleItem(53453, 13, 14)])
print( T.search(minutes_from_midnight(11), minutes_from_midnight(13.5)) )
for h in range( 7, 18 ):
  print( h, T.search(minutes_from_midnight( h ) ) )



