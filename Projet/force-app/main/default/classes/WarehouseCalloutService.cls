public with sharing class WarehouseCalloutService {

    //Retrieves warehouse equipment and synchronizes it with Salesforce.
    private static final String WAREHOUSE_URL = 'https://th-superbadge-apex.herokuapp.com/equipment';

    public static void runWarehouseEquipmentSync(){

        HttpRequest request = new HttpRequest();
        request.setEndpoint(WAREHOUSE_URL);
        request.setMethod('GET');

        Http http = new Http();
        HttpResponse response = http.send(request);
        
        List<Product2> warehouseEquipement = new List<Product2>();
        
        if (response.getStatusCode() == 200){
            List<Object> jsonResponse = (List<Object>)JSON.deserializeUntyped(response.getBody());
            System.debug(response.getBody());
            
            for (Object equipment : jsonResponse){
                Map<String,Object> mapJson = (Map<String,Object>)equipment;
                Product2 myEquipement = new Product2();
                myEquipement.Replacement_Part__c = (Boolean) mapJson.get('replacement');
                myEquipement.Name = (String) mapJson.get('name');
                myEquipement.Maintenance_Cycle__c = (Integer) mapJson.get('maintenanceperiod');
                myEquipement.Lifespan_Months__c = (Integer) mapJson.get('lifespan');
                myEquipement.Cost__c = (Decimal) mapJson.get('lifespan');
                myEquipement.Warehouse_SKU__c = (String) mapJson.get('sku');
                myEquipement.Current_Inventory__c = (Double) mapJson.get('quantity');
                warehouseEquipement.add(myEquipement);
            }
            
            if (warehouseEquipement.size() > 0){
                upsert warehouseEquipement;
                System.debug('Your equipment was synced with the warehouse one');
                System.debug(warehouseEquipement);
            }
            
        }
    }
}