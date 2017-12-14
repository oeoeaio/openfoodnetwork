angular.module("admin.pos").factory "LineItems", ($resource, Orders, Variants) ->
  LineItemResource = $resource '/admin/bulk_line_items/:id/:action.json', {order_id: '@order_id'},
    'add':
      method: 'POST'
    'remove':
      method: 'DELETE'
  new class LineItems
    all: []
    byID: {}

    load: (lineItems) ->
      for lineItem in lineItems
        @all.push lineItem
        @byID[lineItem.id] = lineItem

    linkToOrders: ->
      for lineItem in @all
        @linkToOrder(lineItem)
        @addToOrder(lineItem)

    linkToOrder: (lineItem) ->
      lineItem.order = Orders.byID[lineItem.order.id]

    addToOrder: (lineItem) ->
      lineItem.order.lineItems ?= []
      lineItem.order.lineItems.push lineItem

    linkToVariants: ->
      for lineItem in @all
        @linkToVariant(lineItem)

    linkToVariant: (lineItem) ->
      lineItem.variant = Variants.byID[lineItem.variant.id]

    remove: (lineItem) ->
      params =
        id: lineItem.id
        order_id: lineItem.order.number
      LineItemResource.remove params, (data) =>
        angular.extend(lineItem.order,data)
        lineItems = lineItem.order.lineItems
        index = lineItems.indexOf(lineItem)
        lineItems.splice(index, 1) if index > -1
        index = @all.indexOf(lineItem)
        @all.splice(index, 1) if index > -1
        @byID[lineItem.id] = lineItem
