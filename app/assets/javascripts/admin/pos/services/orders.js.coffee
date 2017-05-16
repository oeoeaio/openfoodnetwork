angular.module("admin.pos").factory "Orders", ->
  new class Orders
    all: []
    byID: {}

    load: (orders) ->
      for order in orders
        @all.push order
        @byID[order.id] = order for order in orders
