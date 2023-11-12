public with sharing class IntegrationUtils {

    public static List<String> getFields(String selectedObject){
        List<String> reqFields = new List<String>();
        Map <String,Schema.SObjectType> gd = Schema.getGlobalDescribe();
        Schema.SObjectType sobjType = gd.get(selectedObject);
        Schema.DescribeSObjectResult r = sobjType.getDescribe();
        Map<String, Schema.SObjectField> mapOfField = r.fields.getMap();
        
        for(String fieldName : mapOfField.keySet()) {
            reqFields.add(fieldName);
        }
        return reqFields;
    }

    public static List<String> addRelationshipObjectToFields(List<String> fieldList, String objectName){
        List<String> newFieldList = new List<String>();
        for(String field : fieldList) {
            newFieldList.add(objectName+'.'+field);
        }
        return newFieldList;
    }
}