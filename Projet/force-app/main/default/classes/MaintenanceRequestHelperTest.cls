@istest
public with sharing class MaintenanceRequestHelperTest {

    private static Vehicle__c createVehicle(){
        Vehicle__c Vehicle = new Vehicle__c (Name = 'SuperTruck');
        return Vehicle;
    }
    
    private static Product2 createEquipment(){
        Product2 equipment = new Product2(
            Name = 'SuperEquipment',
            Lifespan_months__C = 10,
            Maintenance_Cycle__c = 10,
            Replacement_part__c = true);
        return equipment;
    }
    
    private static Case createMaintenanceRequest(id vehicleId, id equipmentId){
        case maintenanceRequest = new case(Type = MaintenanceRequestHelper.REPAIR,
                          Status = MaintenanceRequestHelper.STATUS_NEW,
                          Origin = MaintenanceRequestHelper.REQUEST_ORIGIN,
                          Subject = MaintenanceRequestHelper.REQUEST_SUBJECT,
                          Equipment__c = equipmentId,
                          Vehicle__c = vehicleId);
        return maintenanceRequest;
    }
    
    private static Equipment_Maintenance_Item__c createEquipmentMaintenanceItem(id equipmentId,id requestId){
        Equipment_Maintenance_Item__c equipmentMaintenanceItem = new Equipment_Maintenance_Item__c(Equipment__c = equipmentId,
                                                                            Maintenance_Request__c = requestId);
        return equipmentMaintenanceItem;
    }
    
    
    @istest
    private static void testMaintenanceRequestPositive(){
        Vehicle__c vehicle = createVehicle();
        insert vehicle;
        
        Product2 equipment = createEquipment();
        insert equipment;
        
        case somethingToUpdate = createMaintenanceRequest(vehicle.Id,equipment.Id);
        insert somethingToUpdate;
        
        Equipment_Maintenance_Item__c equipmentMaintenanceItem = createEquipmentMaintenanceItem(equipment.Id,somethingToUpdate.id);
        insert equipmentMaintenanceItem;
        
        Test.startTest();
        somethingToUpdate.status = MaintenanceRequestHelper.CLOSED;
        update somethingToUpdate;
        Test.stopTest();
        
        Case newReq = [SELECT id, subject, type, Equipment__c, Date_Reported__c, Vehicle__c, Date_Due__c
                      FROM case
                      WHERE status =:MaintenanceRequestHelper.STATUS_NEW];
        
        System.assert(newReq.Subject != null);
        System.assertEquals(newReq.Type, MaintenanceRequestHelper.REQUEST_TYPE);
        System.assertEquals(newReq.Equipment__c, equipment.Id);
        System.assertEquals(newReq.Vehicle__c, vehicle.Id);
        System.assertEquals(newReq.Date_Reported__c, System.today());
    }
    
    @istest
    private static void testMaintenanceRequestNegative(){
        Vehicle__c vehicle = createVehicle();
        insert vehicle;
        
        Product2 equipment = createEquipment();
        insert equipment;
        
        Case testCase = createMaintenanceRequest(vehicle.Id, equipment.Id);
        insert testCase;

        Equipment_Maintenance_Item__c item = createEquipmentMaintenanceItem(equipment.Id, testCase.Id);
        insert item;
        
        Test.startTest();
        testCase.Status = MaintenanceRequestHelper.WORKING;
        update testCase;
        Test.stopTest();
       
        System.assertEquals(0, [SELECT COUNT() FROM Case WHERE ParentId = :testCase.Id], 'We should not have created sub case');
    }
    
    @istest
    private static void testMaintenanceRequestBulk(){
        List<Vehicle__C> vehicleList = new List<Vehicle__C>();
        List<Product2> equipmentList = new List<Product2>();
        List<Equipment_Maintenance_Item__c> itemList = new list<Equipment_Maintenance_Item__c>();
        List<case> requestList = new List<case>();
        List<id> oldRequestIds = new List<id>();
        
        for(integer i = 0; i < 300; i++){
           vehicleList.add(createVehicle());
            equipmentList.add(createEquipment());
        }
        insert vehicleList;
        insert equipmentList;
        
        for(integer i = 0; i < 300; i++){
            requestList.add(createMaintenanceRequest(vehicleList.get(i).id, equipmentList.get(i).id));
        }
        insert requestList;
        
        for(integer i = 0; i < 300; i++){
            itemList.add(createEquipmentMaintenanceItem(equipmentList.get(i).id, requestList.get(i).id));
        }
        insert itemList;
        
        Test.startTest();
        for(case req : requestList){
            req.Status = MaintenanceRequestHelper.CLOSED;
            oldRequestIds.add(req.Id);
        }
        update requestList;
        Test.stopTest();
        
        List<case> allRequests = [SELECT id
                                 FROM case
                                 WHERE status =: MaintenanceRequestHelper.STATUS_NEW];
        
        list<Equipment_Maintenance_Item__c> item = [SELECT id
                                                    FROM Equipment_Maintenance_Item__c
                                                    WHERE Maintenance_Request__c IN: oldRequestIds];
        
        System.assert(allRequests.size() == 300);
    }
}