Darkswarm.factory 'Enterprises', (enterprises, CurrentHub, Taxons, Dereferencer, visibleFilter, Matcher, MapsAPI, $rootScope) ->
  new class Enterprises
    enterprises_by_id: {}
    distanceRef: null

    constructor: ->
      # Populate Enterprises.enterprises from json in page.
      @enterprises = enterprises
      # Map enterprises to id/object pairs for lookup.
      for enterprise in enterprises
        @enterprises_by_id[enterprise.id] = enterprise
      # Replace enterprise and taxons ids with actual objects.
      @dereferenceEnterprises()
      @visible_enterprises = visibleFilter @enterprises
      @producers = @visible_enterprises.filter (enterprise)->
        enterprise.category in ["producer_hub", "producer_shop", "producer"]
      @hubs = @visible_enterprises.filter (enterprise)->
        enterprise.category in ["hub", "hub_profile", "producer_hub", "producer_shop"]

    dereferenceEnterprises: ->
      if CurrentHub.hub?.id
        CurrentHub.hub = @enterprises_by_id[CurrentHub.hub.id]
      for enterprise in @enterprises
        @dereferenceEnterprise enterprise

    dereferenceEnterprise: (enterprise) ->
      @dereferenceProperty(enterprise, 'hubs', @enterprises_by_id)
      @dereferenceProperty(enterprise, 'producers', @enterprises_by_id)
      @dereferenceProperty(enterprise, 'taxons', Taxons.taxons_by_id)
      @dereferenceProperty(enterprise, 'supplied_taxons', Taxons.taxons_by_id)

    dereferenceProperty: (enterprise, property, data) ->
      # keep unreferenced enterprise ids
      # in case we dereference again after adding more enterprises
      enterprise.unreferenced |= {}
      collection = enterprise[property]
      unreferenced = enterprise.unreferenced[property] || collection
      enterprise.unreferenced[property] =
        Dereferencer.dereference_from unreferenced, collection, data

    addEnterprises: (new_enterprises) ->
      return unless new_enterprises && new_enterprises.length
      for enterprise in new_enterprises
        @enterprises_by_id[enterprise.id] = enterprise

    flagMatching: (query) ->
      for enterprise in @enterprises
        enterprise.matches_name_query = if query? && query.length > 0
          Matcher.match([enterprise.name], query)
        else
          false

    findPlace: (query) ->
      return @resetDistance() unless query?.length > 0
      MapsAPI.find query, (results, status) =>
        if status == google.maps.places.PlacesServiceStatus.OK
          if results[0]
            @distanceRef = results[0].description
            @calculateDistance(results[0].place_id)
          else
            @resetDistance()
        else
          @resetDistance()

    calculateDistance: (placeId) ->
      MapsAPI.geocodePlaceID placeId, (results, status) =>
        if status == MapsAPI.GeoOK
          $rootScope.$apply =>
            @setDistanceFrom(results[0].geometry.location)
        else
          console.log "Geocoding failed for the following reason: #{status}"
          $rootScope.$apply =>
            @resetDistance()

    setDistanceFrom: (locatable) ->
      for enterprise in @hubs
        enterprise.distance = MapsAPI.distanceBetween enterprise, locatable
      $rootScope.$broadcast 'enterprisesChanged'

    resetDistance: =>
      @distanceRef = null
      enterprise.distance = null for enterprise in @enterprises
