angular.module("admin.pos").factory "DataLoader", ($http, LineItems, Orders, Variants, Products) ->
  new class DataLoader
    data = null

    load: (shopID, orderCycleID)->
      params=
        shop_id: shopID
        order_cycle_id: orderCycleID

      $http.get('/admin/pos/data.json', params: params).then (response) ->
        @data = response.data
        LineItems.load(@data.line_items)
        Orders.load(@data.orders)
        Products.load(@data.products)
        Variants.load(@data.variants)

        LineItems.linkToOrders(Orders.byID)
        LineItems.linkToVariants(Variants.byID)
        Variants.linkToProducts(Products.byID)
      , (response) ->
        #something
