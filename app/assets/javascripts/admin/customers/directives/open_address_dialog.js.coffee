angular.module("admin.customers").directive 'openAddressDialog', (EditAddressDialog) ->
  restrict: 'A'
  scope: true
  controller: 'EditAddressController'
  link: (scope, element, attr) ->
    scope.addressType = if attr.id == 'bill-address-link' then 'bill_address' else 'ship_address'
    scope.address = scope.customer[scope.addressType]
    scope.states = scope.filterStates(scope.address?.country_id)

    element.bind 'click', (e) ->
      scope.dialog ||= new EditAddressDialog(scope)
      scope.dialog.open()
      scope.$apply()
