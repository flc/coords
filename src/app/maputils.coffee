angular.module "mapUtils", []


.service "MapUtils", () ->

  getBoundsZoomLevel: (bounds, mapDim) ->

    latRad = (lat) ->
      sin = Math.sin(lat * Math.PI / 180)
      radX2 = Math.log((1 + sin) / (1 - sin)) / 2
      Math.max(Math.min(radX2, Math.PI), -Math.PI) / 2

    zoom = (mapPx, worldPx, fraction) ->
      Math.floor Math.log(mapPx / worldPx / fraction) / Math.LN2

    WORLD_DIM =
      height: 256
      width: 256
    ZOOM_MAX = 21
    ne = bounds.getNorthEast()
    sw = bounds.getSouthWest()
    latFraction = (latRad(ne.lat()) - latRad(sw.lat())) / Math.PI
    lngDiff = ne.lng() - sw.lng()
    lngFraction = (if lngDiff < 0 then lngDiff + 360 else lngDiff) / 360
    latZoom = zoom(mapDim.height, WORLD_DIM.height, latFraction)
    lngZoom = zoom(mapDim.width, WORLD_DIM.width, lngFraction)

    Math.min latZoom, lngZoom, ZOOM_MAX

  getMPolygonCoords: (polys) ->
    data = []
    for poly in polys
      path = poly.getPath()

      # XXX autocomplete polygon
      first = path.getAt(0)
      last = path.getAt(path.length - 1)
      if first.lng() isnt last.lng() or first.lat() isnt last.lat()
        path.push(first)

      p = []
      for c in path.getArray()
        p.push([c.lng(), c.lat()])
      data.push([p])
    return data

  getPolygonPathsFromBounds: (bounds) ->
    paths = new google.maps.MVCArray()
    path = new google.maps.MVCArray()
    ne = bounds.getNorthEast()
    sw = bounds.getSouthWest()
    path.push(ne)
    path.push(new google.maps.LatLng(sw.lat(), ne.lng()))
    path.push(sw)
    path.push(new google.maps.LatLng(ne.lat(), sw.lng()))
    paths.push(path)
    return paths

  getDataFromMPolygon: (mpoly) ->
    shapes = []
    bounds = new google.maps.LatLngBounds()
    for coords in mpoly.coordinates
      # from the backend coords are reversed
      paths = []
      for c in coords[0]
        paths.push([c[1], c[0]])
        latlng = new google.maps.LatLng(c[1], c[0])
        bounds.extend(latlng)
      shapes.push({
        'paths': paths,
        'name': 'polygon',
        })
    center= bounds.getCenter()
    center = [center.lat(), center.lng()]

    # zoom = getBoundsZoomLevel(bounds, {'height': 160, 'width': 160})
    data =
      bounds: bounds
      center: center
      shapes: shapes
      # zoom: zoom
    return data

  getInitialPolyFromMap: (map) ->
    bounds = map.getBounds()
    return @getPolygonPathsFromBounds(bounds)

  getBoundsFromCoords: (coords) ->
    bounds = new google.maps.LatLngBounds()
    for coord in coords
      latlng = new google.maps.LatLng(coord[0], coord[1])
      bounds.extend(latlng)
    return bounds

  decodePath: (path) ->
    decodedPolyline = []
    for o, idx in google.maps.geometry.encoding.decodePath(path)
      decodedPolyline.push([o.lat(), o.lng()])
    return decodedPolyline

  triggerResize: (map) ->
    google.maps.event.trigger(map, 'resize')
