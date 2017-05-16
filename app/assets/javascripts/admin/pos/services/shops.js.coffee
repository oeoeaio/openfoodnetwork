angular.module("admin.pos").factory "Shops", ($resource) ->
  EnterpriseResource = $resource '/admin/enterprises.json'

  new class Shops
    all: []

    load: (lineItems) ->
      params =
        ams_prefix: 'basic'
      EnterpriseResource.query params, (response) =>
        for e in response
          @all.push(e) if e.is_distributor
