angular.module("admin.pos").factory "OrderCycles", ($resource) ->
  OrderCycleResource = $resource '/admin/order_cycles.json'

  new class OrderCycles
    all: []

    load: (lineItems) ->
      params =
        ams_prefix: 'basic'
        as: 'distributor'
      OrderCycleResource.query params, (response) =>
        @all.push(oc) for oc in response
