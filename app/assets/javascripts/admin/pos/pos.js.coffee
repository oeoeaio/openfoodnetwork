angular.module("admin.pos", ['ngSanitize','ngResource']).config ($httpProvider) ->
  $httpProvider.defaults.headers.common["X-CSRF-Token"] = $("meta[name=csrf-token]").attr("content");
  $httpProvider.defaults.headers.common["Accept"] = "application/json, text/javascript, */*";
