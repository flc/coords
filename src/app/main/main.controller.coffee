angular.module "app"


.controller "MainCtrl", (
  $scope, $interval, $timeout, _, moment, NgMap, MapUtils
) ->
  'ngInject'
  vm = this

  getSelected = ->
    _.filter(vm.tableData.body, 'isSelected')

  toggleSelect = (row) ->
    row.isSelected = !row.isSelected
    updateMarkerVisibility()

  selectAll = ->
    newValue = not vm.isAllSelected()
    for row in vm.tableData.body
      row.isSelected = newValue
    updateMarkerVisibility()

  deselectAll = ->
    for row in vm.tableData.body
      row.isSelected = false
    updateMarkerVisibility()

  isAllSelected = ->
    if vm.tableData.body.length <= 0
      return false
    vm.tableData.body.length is getSelected().length

  moveSelect = (type="next") ->
    selected = getSelected()
    if type is "next"
      # if nothing is selected, just select the first point
      if selected.length <= 0
        vm.tableData.body[0].isSelected = true
        return

    indexes = []
    for s in selected
      ind = _.indexOf(vm.tableData.body, s)
      indexes.push(ind)
    max = Math.max.apply(Math, indexes)
    min = Math.min.apply(Math, indexes)
    diff = max - min
    # deselect all
    vm.deselectAll()
    # select new ones
    newIndexes = _.map indexes, (e) ->
      if type is 'next'
        e + diff + 1
      else
        e - diff - 1
    for row, i in vm.tableData.body
      if i in newIndexes
        row.isSelected = true

    updateMarkerVisibility()

  selectNext = ->
    moveSelect('next')

  selectPrevious = ->
    moveSelect('previous')

  updateMarkerVisibility = ->
    NgMap.getMap().then (map) ->
      if map.markers
        selected = getSelected()

        if 'm' not in vm.options.mapItems
          # hide all markers
          for markerId, marker of map.markers
            marker.setVisible(false)
        else
          for row, i in vm.tableData.body
            visible = row.isSelected
            map.markers[i].setVisible(visible)

        polylines = [vm.polylines[0]]
        if selected.length > 0 and 'p' in vm.options.mapItems
          newPolyline = genPolyline(selected)
          polylines.push(newPolyline)
        vm.polylines = polylines
      return

  updatePolylineVisibility = ->
    NgMap.getMap().then (map) ->
      if map.shapes
        visible = 'p' in vm.options.mapItems
        for sId, s of map.shapes
          s.setVisible(visible)
      return

  getBounds = (onlySelected) ->
    coords = []
    if onlySelected
      items = getSelected()
    else
      items = vm.tableData.body
    if items.length <= 0
      return null
    for c, i in items
      coords.push([c.data[0], c.data[1]])
    return MapUtils.getBoundsFromCoords(coords)

  fitBounds = (onlySelected=false) ->
    bounds = getBounds(onlySelected)
    if bounds
      NgMap.getMap().then (map) ->
        map.fitBounds(bounds)

  genMarkers = ->
    markers = []
    for row, i in vm.tableData.body
      data = row.data
      markers.push
        position: [data[0], data[1]]
        id: i
        data: data
    vm.markers = markers

  genPolyline = (rows) ->
    path = []
    dPath = new google.maps.MVCArray()
    for row, i in rows
      data = row.data
      path.push([data[0], data[1]])
      dPath.push(
        new google.maps.LatLng(data[0], data[1])
        )

    console.log "polyline distance: ", google.maps.geometry.spherical.computeLength(dPath)
    polyline =
      id: 0
      name: "polyline"
      path: path
      editable: false
      draggable: false
      geodesic: true
      visible: 'p' in vm.options.mapItems
      strokeColor: "#FF8C00"
      strokeOpacity: 0.6
      strokeWeight: 8
    return polyline

  genPolylines = ->
    polyline = genPolyline(vm.tableData.body)
    polyline.strokeColor = "#007BA7"
    polyline.strokeOpacity = 1
    polyline.strokeWeight = 3
    # polylineSelected = genPolyline(getSelected())
    vm.polylines = [polyline]

  processData = ->
    vm.errors = {}
    csv = _.trim(vm.form.data)
    if not csv
      return
    results = Papa.parse(csv)
    if results.errors.length > 0
      vm.errors.data = results.errors
      return

    body = []
    prevRow = null
    for row, i in results.data[1..]
      distance = duration = speed_km = 0

      if prevRow
        p1 = new google.maps.LatLng(prevRow[0], prevRow[1])
        p2 = new google.maps.LatLng(row[0], row[1])
        distance = google.maps.geometry.spherical.computeDistanceBetween(p1, p2)
        m1 = moment(prevRow[2])
        m2 = moment(row[2])
        duration = moment.duration(m2.diff(m1)).seconds()
        if duration
          speed_ms = distance / duration
          speed_km = speed_ms * 3.6

      row.push [distance, duration, speed_km]...
      body.push
        isSelected: true
        data: row
        id: i
        label: i
      prevRow = row

    header = results.data[0]
    header.push ["distance (m)", "duration (sec)", "speed (km/h)"]...
    vm.tableData =
      'header': header
      'body': body

    console.log vm.tableData
    genMarkers()
    genPolylines()
    vm.tabs.activeTab = "table"
    $timeout ->
      fitBounds()
      updateMarkerVisibility()

  simulateStart = ->
    # vm.deselectAll()
    vm.simulateRunning = true
    vm.simulatePromise = $interval (->
      vm.selectNext()
      ), vm.options.simulateStepDelay

  simulateStop = ->
    if vm.simulatePromise
      $interval.cancel(vm.simulatePromise)
      vm.simulatePromise = null

  showMarkerInfo = (event, marker) ->
    NgMap.getMap().then (map) ->
      _marker = map.markers[marker.id]
      console.log marker, _marker
      iw = new google.maps.InfoWindow({
        content: "<div>#{marker.id} | #{marker.data[2]} | ID: #{marker.data[3]}</div><div>#{marker.position}</div>"
        })
      iw.open(map, _marker)

  calcDistanceSelected = ->
    selected = getSelected()
    distance = 0
    prevRow = null
    for row, i in selected
      dist = 0
      if prevRow
        p1 = new google.maps.LatLng(prevRow.data[0], prevRow.data[1])
        p2 = new google.maps.LatLng(row.data[0], row.data[1])
        dist = google.maps.geometry.spherical.computeDistanceBetween(p1, p2)
      distance += dist
      prevRow = row
    return distance

  init = ->
    SAMPLE_DATA = """
    lat,lon,timestamp,id
    47.487881572818225,19.061023492137682,2016-02-23 16:15:31+00:00,3784491
    47.48797694058251,19.06098388530095,2016-02-23 16:15:34+00:00,3784492
    47.48809410143515,19.06089699925543,2016-02-23 16:15:37+00:00,3784493
    47.48832866147387,19.06064564083503,2016-02-23 16:16:31+00:00,3784509
    47.488392560526925,19.060581023718548,2016-02-23 16:16:43+00:00,3784510
    47.48848821697622,19.060484291970685,2016-02-23 16:16:46+00:00,3784511
    47.4886487279412,19.060757757728286,2016-02-23 16:16:52+00:00,3784513
    47.488772897603724,19.061011532240194,2016-02-23 16:16:55+00:00,3784514
    47.488864138842395,19.061122200872305,2016-02-23 16:16:58+00:00,3784515
    47.48896661562314,19.061251640158332,2016-02-23 16:17:01+00:00,3784516
    47.489070983832946,19.06138346923264,2016-02-23 16:17:04+00:00,3784517
    47.48915810770904,19.061480868371603,2016-02-23 16:17:07+00:00,3784518
    47.4892229291431,19.0615460994352,2016-02-23 16:17:46+00:00,3784531
    47.489270262284144,19.061584089629527,2016-02-23 16:18:07+00:00,3784532
    47.489437846649935,19.061718595651435,2016-02-23 16:18:10+00:00,3784533
    47.489629099999995,19.0618721,2016-02-23 16:18:13+00:00,3784534
    47.4898321,19.0619311,2016-02-23 16:18:16+00:00,3784535
    47.49027244516439,19.06196608976883,2016-02-23 16:18:19+00:00,3784536
    47.49059438881002,19.06188860800834,2016-02-23 16:18:22+00:00,3784537
    47.49090385022463,19.06182119321057,2016-02-23 16:18:25+00:00,3784538
    47.49117195974445,19.06176170877395,2016-02-23 16:18:28+00:00,3784539
    47.491374484796424,19.061712119317782,2016-02-23 16:18:31+00:00,3784540
    47.4915053290406,19.061670748720168,2016-02-23 16:18:34+00:00,3784541
    47.49167335804138,19.061572137781233,2016-02-23 16:18:37+00:00,3784542
    47.49186132445274,19.06141539720358,2016-02-23 16:18:40+00:00,3784543
    47.49206754925754,19.061308558516142,2016-02-23 16:18:43+00:00,3784544
    47.4923111759283,19.061182972187925,2016-02-23 16:18:46+00:00,3784545
    47.492563172619754,19.061049734556526,2016-02-23 16:18:49+00:00,3784546
    47.49284258735668,19.060900336946876,2016-02-23 16:18:52+00:00,3784547
    47.49313097596878,19.060745525068402,2016-02-23 16:18:55+00:00,3784548
    47.49344465320568,19.06057649906711,2016-02-23 16:18:58+00:00,3784549
    """
    sampleCSV = SAMPLE_DATA

    NgMap.getMap().then (map) ->
      vm.map = map

    vm.form =
      data: sampleCSV
    vm.errors = {}
    vm.options =
      simulateStepDelay: 100
      mapItemOptions: [
        {
          'value': 'm'
          'label': 'Markers'
        },
        {
          'value': 'p'
          'label': 'Polylines'
        }
      ]
      mapItems: ['m', 'p']
    vm.simulatePromise = null
    vm.tableData = {
      'header': [],
      'body': [],
    }
    vm.tabs =
      activeTab: "input"
    vm.mapOptions =
      zoom: 6
      control: {}
      options: {}
      markers: []
      polylines: []

    $scope.$watch (->
      vm.options.mapItems
    ), (value) ->
      updateMarkerVisibility()
      updatePolylineVisibility()

     # scope functions
    vm.processData = processData
    vm.toggleSelect = toggleSelect
    vm.selectAll = selectAll
    vm.deselectAll = deselectAll
    vm.isAllSelected = isAllSelected
    vm.selectNext = selectNext
    vm.selectPrevious = selectPrevious
    vm.simulateStart = simulateStart
    vm.simulateStop = simulateStop
    vm.getSelected = getSelected
    vm.updateMarkerVisibility = updateMarkerVisibility
    vm.fitBounds = fitBounds
    vm.showMarkerInfo = showMarkerInfo
    vm.calcDistanceSelected = calcDistanceSelected

    window.scope = vm

  init()

  return
