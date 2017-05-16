angular.module("admin.pos").directive "orderSelect", ($sanitize, Orders) ->
  require: 'ngModel'
  restrict: 'C'
  scope:
    minSearch: "@?"
  link: (scope, element, attrs, ngModel) ->
    scope.$on 'orders.loaded', ->
      item.name = $sanitize(item.name) for item in Orders.all
      element.select2
        width: "100%"
        placeholder: "Select an order..."
        minimumResultsForSearch: scope.minSearch || 0
        data: { results: Orders.all, text: 'full_name' }
        formatSelection: (item) ->
          "<b>#{item.full_name}</b> (#{item.completed_at})"
        formatResult: (item) ->
          "<b>#{item.full_name}</b> (#{item.completed_at})"

      element.on 'select2-selecting', (e) ->
        ngModel.$setViewValue(e.val)

    attrs.$observe 'disabled', (value) ->
      element.select2('enable', !value)

    ngModel.$formatters.push (value) ->
      element.select2('val', value)
      value
