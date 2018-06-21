angular.module('admin.customers').controller 'EditAddressController', ($scope, $filter, Customers) ->
    $scope.dialog = null
    $scope.errors = []

    $scope.$watch 'address.country_id', (newCountryID) ->
      if newCountryID
        $scope.states = $scope.filterStates(newCountryID)
        $scope.clearState() unless $scope.addressStateMatchesCountry()

    $scope.updateAddress = ->
      $scope.edit_address_form.$setPristine()
      if $scope.edit_address_form.$valid
        Customers.update($scope.address, $scope.customer, $scope.addressType).$promise.then (data) ->
          $scope.customer = data
          $scope.errors = []
          $scope.dialog.close()
          StatusMessage.display('success', t('admin.customers.index.update_address_success'))
      else
        $scope.errors.push(t('admin.customers.index.update_address_error'))

    $scope.filterStates = (countryID) ->
      return [] unless countryID
      $filter('filter')($scope.availableCountries, {id: parseInt(countryID)}, true)[0].states

    $scope.clearState = ->
      $scope.address.state_id = ""

    $scope.addressStateMatchesCountry = ->
      $scope.states.some (state) -> state.id == $scope.address.state_id
