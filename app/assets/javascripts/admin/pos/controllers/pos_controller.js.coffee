angular.module("admin.pos").controller "POSCtrl", ($scope, $filter, DataLoader, Shops, OrderCycles, CurrentOrder, Orders, Variants) ->
  Shops.load()
  OrderCycles.load()
  $scope.shops = Shops.all
  $scope.orderCycles = [{id: 0, name: 'Please select a shop first'}]
  $scope.currentShopID = 0
  $scope.currentOrderCycleID = 0
  $scope.currentOrderID = 0
  $scope.config = { view: 'products' }

  $scope.$watch 'shopID', (newVal, oldVal) ->
    return unless newVal > 0
    $scope.orderCycles = $filter('filter')(OrderCycles.all, (oc) ->
      oc.distributors.some (d) -> d.id == newVal
    )

  $scope.$watch 'orderCycleID', (newVal, oldVal) ->
    return unless newVal > 0
    DataLoader.load($scope.shopID, newVal).then ->
      $scope.variants = Variants.all
      $scope.$broadcast('orders.loaded')

  $scope.$watch 'orderID', (newVal, oldVal) ->
    return unless newVal > 0
    CurrentOrder.order = Orders.byID[newVal]
    $scope.currentOrder = CurrentOrder.order
    $scope.config.view = 'products'

  $scope.addLineItem = (variant) ->
    CurrentOrder.addVariant(variant)

  $scope.removeLineItem = (lineItem) ->
    CurrentOrder.removeLineItem(lineItem)
