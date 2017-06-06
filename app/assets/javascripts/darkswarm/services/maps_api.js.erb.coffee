Darkswarm.service "MapsAPI", ->
  new class MapsAPI
    GeoOK: google.maps.GeocoderStatus.OK
    PlacesOK: google.maps.places.PlacesServiceStatus.OK
    country: "<%= Spree::Country.find_by_id(Spree::Config[:default_country_id]).iso %>"

    # Usage:
    # MapsAPI.geocode address, (results, status) ->
    #   if status == MapsAPI.GeoOK
    #     console.log results[0].geometry.location
    #   else
    #     console.log "Error: #{status}"
    find: (input, callback) ->
      service = new google.maps.places.AutocompleteService()
      service.getPlacePredictions({input: input, types: ['(cities)'], componentRestrictions: { country: @country }},callback)

    geocodePlaceID: (placeId, callback) ->
      geocoder = new google.maps.Geocoder()
      geocoder.geocode({'placeId': placeId}, callback)

    distanceBetween: (src, dst) ->
      google.maps.geometry.spherical.computeDistanceBetween @toLatLng(src), @toLatLng(dst)

    # Wrap an object in a google.maps.LatLng if it has not been already
    toLatLng: (locatable) ->
      if locatable.lat?
        locatable
      else
        new google.maps.LatLng locatable.latitude, locatable.longitude
