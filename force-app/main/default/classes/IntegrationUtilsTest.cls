@isTest
private class IntegrationUtilsTest {

    @isTest
    static void testGetFields() {
        // Test the getFields method with a known object (e.g., Account)
        List<String> fields = IntegrationUtils.getFields('Account');
        System.assertNotEquals(0, fields.size(), 'Field list should not be empty');
        System.assert(fields.contains('name'), 'Field list should contain the "Name" field');

        // Test the addRelationshipObjectToFields method
        List<String> resultFields = IntegrationUtils.addRelationshipObjectToFields(fields, 'Account');

        System.assertEquals(fields.size(), resultFields.size(), 'Result field list should have the same size as input');
        System.assert(resultFields.contains('Account.name'), 'Result field list should contain "Account.Name"');
    }
}
