from django.contrib import admin

from . import models

admin.site.register(models.CommerceMerchant)
admin.site.register(models.Branch)
admin.site.register(models.Product)
admin.site.register(models.Warehouse)
admin.site.register(models.StockItem)
admin.site.register(models.SalesOrder)
admin.site.register(models.Supplier)
admin.site.register(models.CustomerProfile)
admin.site.register(models.PosSession)
