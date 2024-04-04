public with sharing class MaintenanceRequestHelper {
    
    // Creates a new Case with Maintenance Request whenever a case gets closed
    // Description for methods
    // Comments in the code
    // Meaningfull names for variables
    // Local variables = camelCase & starts with lowercase
    public static final String STATUS_NEW = 'New';
    public static final string WORKING = 'Working';
    public static final string CLOSED = 'Closed';
    public static final string REPAIR = 'Repair';
    public static final string REQUEST_ORIGIN = 'Web';
    public static final string REQUEST_TYPE = 'Routine Maintenance';
    public static final string REQUEST_SUBJECT = 'Testing subject';

    public static void createMaintenanceRequestsForClosedCases (List<Case> newCases, Map<Id,Case> oldCasesMap) {
        Set<Id> caseIdsToProcess = new Set<Id>();
        for (Case newCase : newCases){
            if (oldCasesMap.get(newCase.Id).Status != CLOSED 
                    && newCase.Status == CLOSED
                    && (newCase.Type == REPAIR 
                    || newCase.Type == REQUEST_TYPE))
            {
                caseIdsToProcess.add(newCase.Id);
            }
        }
        
        if (caseIdsToProcess.isEmpty() == false) {
            List<Case> newRoutineCases = new List<Case>();
            Map<Id,Case> closedCasesMap = new Map<Id,Case>(
                [SELECT Id, Vehicle__c, Equipment__c, Equipment__r.Maintenance_Cycle__c,
                    (SELECT Id,Equipment__c,Quantity__c 
                    FROM Equipment_Maintenance_Items__r) 
                FROM Case 
                WHERE Id IN :caseIdsToProcess]);
           
            List<AggregateResult> results = 
                [SELECT Maintenance_Request__c, MIN(Equipment__r.Maintenance_Cycle__c)cycle 
                FROM Equipment_Maintenance_Item__c 
                WHERE Maintenance_Request__c IN :caseIdsToProcess 
                GROUP BY Maintenance_Request__c];
            
            Map<Id,Decimal> maintenanceCycles = new Map<ID,Decimal>();
            for (AggregateResult ar : results){ 
                maintenanceCycles.put((Id) ar.get('Maintenance_Request__c'), (Decimal) ar.get('cycle'));
            }
            
            for (Case closedCase : closedCasesMap.values()){
                Case newCase = new Case (
                    ParentId = closedCase.Id,
                    Status = STATUS_NEW,
                    Subject = 'Routine Maintenance',
                    Type = REQUEST_TYPE,
                    Vehicle__c = closedCase.Vehicle__c,
                    Equipment__c = closedCase.Equipment__c,
                    Origin = REQUEST_ORIGIN,
                    Date_Reported__c = Date.today()
                );
                
                if (maintenanceCycles.containskey(closedCase.Id)){
                    newCase.Date_Due__c = Date.today().addDays((Integer) maintenanceCycles.get(closedCase.Id));
                }
                
                newRoutineCases.add(newCase);
            }
            
           insert newRoutineCases;
            
           // Cloning the Equipment maintenance items in order to link the vehicules from original case 
           // to the newly created case
           List<Equipment_Maintenance_Item__c> clonedItems = new List<Equipment_Maintenance_Item__c>();
           for (Case newCase : newRoutineCases){
                for (Equipment_Maintenance_Item__c item : closedCasesMap.get(newCase.ParentId).Equipment_Maintenance_Items__r){
                    Equipment_Maintenance_Item__c clonedItem = item.clone();
                    clonedItem.Maintenance_Request__c = newCase.Id;
                    clonedItems.add(clonedItem);
                }
            }
            insert clonedItems;
        }
    }
}