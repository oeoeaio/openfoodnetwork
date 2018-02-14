Darkswarm.controller "CartCtrl", ($scope, Cart, $timeout, $injector) ->
  $scope.Cart = Cart
  $scope.Alteration = $injector.get('alteration') if $injector.has('alteration')
