angular.module('admin.customers').factory 'EditAddressDialog', ($compile, $templateCache, DialogDefaults) ->
  class EditAddressDialog
    template: null

    constructor: (scope) ->
      @template = $compile($templateCache.get('admin/edit_address_dialog.html'))(scope)
      @template.dialog(DialogDefaults)

    open: ->
      @template.dialog('open')

    close: ->
      @template.dialog('close')
