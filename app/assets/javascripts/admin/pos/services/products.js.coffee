angular.module("admin.pos").factory "Products", ->
  new class Products
    all: []
    byID: {}

    load: (products) ->
      for product in products
        @all.push product
        @byID[product.id] = product

        product.primaryImage = product.images[0]?.small_url if product.images
        product.primaryImageOrMissing = product.primaryImage || "/assets/noimage/small.png"
