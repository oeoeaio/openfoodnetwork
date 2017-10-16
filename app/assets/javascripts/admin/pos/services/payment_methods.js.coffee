angular.module("admin.pos").factory "PaymentMethods", ->
  new class PaymentMethods
    all: []

    load: (payment_methods) ->
      for payment_method in payment_methods
        @all.push payment_method
