trigger MaintenanceRequest on Case (before update, after update) {

    if(Trigger.isUpdate && Trigger.isAfter){

        MaintenanceRequestHelper.createMaintenanceRequestsForClosedCases(Trigger.New, Trigger.OldMap);

    }

}