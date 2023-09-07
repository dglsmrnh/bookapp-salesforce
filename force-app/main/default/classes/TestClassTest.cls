public with sharing class TestClassTest {
    @IsTest
    public static void test(){
        
        Test.startTest();
        TestClass t = new TestClass();
        Test.stopTest();
        
    }
}