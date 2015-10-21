
############################################################################################################
# njs_path                  = require 'path'
# njs_fs                    = require 'fs'
#...........................................................................................................
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'SCRATCH/cid-sets'
log                       = CND.get_logger 'plain',     badge
info                      = CND.get_logger 'info',      badge
whisper                   = CND.get_logger 'whisper',   badge
alert                     = CND.get_logger 'alert',     badge
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
echo                      = CND.echo.bind CND

# morton                    = require 'morton'

# ranges = [
#   [ 3,  10, ]
#   [ 10,  3, ]
#   [ 3,  3, ]
#   [ 10,  10, ]
#   [ 1,  1, ]
#   [ 2,  2, ]
#   [ 3,  3, ]
#   [ 4,  4, ]
#   [ 5,  5, ]
#   [ 10,  10, ]
#   [ 11,  11, ]
#   [ 110,  110, ]
#   ]

# for range in ranges
#   debug range, morton range...

IntervalTree  = require 'interval-tree2'
itree         = new IntervalTree 300 # 300 : the center of the tree
itree.add 0, 10
itree.add 5, 5.5
itree.add 3, 8
itree.add 4, 4.5
itree.add 6, 7

for probe in [ -1 .. 10 ]
  matches = itree.search probe
  unless matches.length > 0
    warn probe, "no matches"
    continue
  matches.sort ( a, b ) ->
    return +1 if a[ 'id' ] < b[ 'id' ]
    return -1 if a[ 'id' ] > b[ 'id' ]
    return  0
  for match, idx in matches
    { start, end, id, } = match
    ( if idx is 0 then help else whisper ) probe, [ start, end, ], rpr id



#features where first and second numbers are start and end coordinates.
#Third element is the id of the feature.

features = [
  [1,90,'A']
  [90,125,'B']
  [25,60,'C']
  [100,170,'D']
  [170,220,'E']
  [220,250,'F']
  [600,700,'G']
  [120,125,'H']
  [500,550,'I']
  [1000,1200,'J']
  [800,850,'K']
  [1100,1500,'L'] ]

# The second and third arguments are the index/key for the start and end
# coodinates in the data array. For our data, our elements are in the format of:

# [start coordinate, end coordinate, feature id]

# The start coordinate is the 0 index and end coordinate is the 1st index.

# The third and fourth argument is the start and end of the total search space.

myTree = intervalTree(features, 0, 1, 1, 2000)


#this will find all features between 20 and 200
results = myTree.findRange([20,200])


`
//accessory functions for finding overlap
function ptWithin(pt, subject) {
  if (pt >= subject[0] && pt <= subject[1]) return true;
  return false;
}

function overlap(query, subject) {
  if (self.ptWithin(query[0], subject) || self.ptWithin(query[1], subject) || self.ptWithin(subject[0], query) || self.ptWithin(subject[1], query)) return true;
  return false;
}

//accessory function to remove redundancies in an array
function unique(a) {
  var temp = {};
  var len = a.length;

  if (len > 0) {
    do {
      len --;
      temp[a[len]] = true;
    } while (len)
  }

  var r = [];
  for (var k in temp) r.push(k);
  return r;
}

//recursively finds features within find range, same as the python implementation
function find(node, findRange, start, end) {
  var data = [];
  var left = [start, node[0]];
  var right = [node[0], end];
  if (overlap(left, findRange)) {
    data = data.concat(node[3]);
    if (node[1] != -1) data = data.concat(find(node[1], findRange, left[0], left[1]));
  }
  if (overlap(right, findRange)) {
    data = data.concat(node[3]);
    if (node[2] != -1) data = data.concat(find(node[2], findRange, right[0], right[1]));
  }
  return unique(data);
}

//to use the previous functions
results = find(myTree, [1,220], 1, 2000);
//results now contains the ids of the features between 1 and 220
`


