angular.module "app"


.controller "MainCtrl", ($scope, _, maps) ->

  $scope.processData = ->
    $scope.errors = {}
    csv = _.trim($scope.form.data)
    if not csv
      return
    results = Papa.parse(csv)
    if results.errors.length > 0
      $scope.errors.data = results.errors
      return

    body = []
    for row in results.data[1..]
      body.push
        isSelected: false
        data: row
    $scope.tableData =
      'header': results.data[0]
      'body': body
    $scope.tableData.body[0].isSelected = true
    $scope.genMarkers(centerMap=true)
    $scope.tabs.activeTab = "table"

  getSelected = ->
    _.filter($scope.tableData.body, 'isSelected')

  $scope.selectAll = ->
    newValue = not $scope.isAllSelected()
    for row in $scope.tableData.body
      row.isSelected = newValue

  $scope.deselectAll = ->
    for row in $scope.tableData.body
      row.isSelected = false

  $scope.isAllSelected = ->
    if $scope.tableData.body.length <= 0
      return false
    $scope.tableData.body.length is getSelected().length

  $scope.genMarkers = (centerMap=false) ->
    markers = []
    selected = getSelected()
    for row, i in selected
      data = row.data
      markers.push
        latitude: data[0]
        longitude: data[1]
        title: "Timestamp: #{data[2]} | ID: #{data[3]}"
        id: data[3]
        idKey: 'id'
    $scope.markers = markers
    if centerMap
      if markers.length > 0
        $scope.map.center =
          latitude: markers[0].latitude
          longitude: markers[0].longitude

  moveSelect = (type="next") ->
    selected = getSelected()
    if type is "next"
      # if nothing is selected, just select the first point
      if selected.length <= 0
        $scope.tableData.body[0].isSelected = true
        return

    indexes = []
    for s in selected
      ind = _.indexOf($scope.tableData.body, s)
      indexes.push(ind)
    max = Math.max.apply(Math, indexes)
    min = Math.min.apply(Math, indexes)
    diff = max - min
    # deselect all
    $scope.deselectAll()
    # select new ones
    newIndexes = _.map indexes, (e) ->
      if type is 'next'
        e + diff + 1
      else
        e - diff - 1
    for row, i in $scope.tableData.body
      if i in newIndexes
        row.isSelected = true

  $scope.selectNext = ->
    moveSelect('next')

  $scope.selectPrevious = ->
    moveSelect('previous')

  init = ->
    sampleCSV = "lat,lon,timestamp,id\n" +
                "47.52427566666667,19.1174815,2015-06-05 11:27:06+00:00,1\n" +
                "47.5242725,19.117523333333335,2015-06-05 11:27:18+00:00,2\n" +
                "47.523268,19.119504166666665,2015-06-05 11:27:39+00:00,3\n" +
                "47.52202033333333,19.122143166666667,2015-06-05 11:28:09+00:00,4\n" +
                "47.522723166666665,19.120615833333332,2015-06-05 11:28:37+00:00,5\n" +
                "47.52007583333334,19.125986833333332,2015-06-05 11:28:48+00:00,6\n" +
                "47.519962,19.12616866666667,2015-06-05 11:29:00+00:00,7\n" +
                "47.5198505,19.126435833333332,2015-06-05 11:29:12+00:00,8\n" +
                "47.519719333333335,19.126806333333334,2015-06-05 11:29:22+00:00,9\n" +
                "47.519552833333336,19.127412333333332,2015-06-05 11:29:31+00:00,10\n" +
                "47.5184085,19.128141333333332,2015-06-05 11:40:16+00:00,11\n" +
                "47.51837233333333,19.128385333333334,2015-06-05 11:40:34+00:00,12\n"

    $scope.form =
      data: sampleCSV
    $scope.errors = {}
    $scope.options = {}
    $scope.tableData = {
      'header': [],
      'body': [],
    }
    $scope.tabs =
      activeTab: "input"

    $scope.map =
      center:
        latitude: 47.49
        longitude: 19.04
      zoom: 6
      control: {}
    $scope.maps = maps
    $scope.markers = []

    $scope.$watch "tableData.body", (->
      $scope.genMarkers()
      ), true

  init()


