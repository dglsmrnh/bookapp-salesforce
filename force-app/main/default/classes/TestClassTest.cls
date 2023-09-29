@IsTest
public with sharing class TestClassTest {
    @IsTest
    public static void test(){
        
        Test.startTest();
        TestClass t = new TestClass();
        t.showDebug(); //
        Test.stopTest();
        
    }
}