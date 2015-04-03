module tests.pass.should;

import unit_threaded;

void testEquals() {
    5.should == 5;
    2.shouldNot == 5;

    "foo".should == "foo";
    "foo".shouldNot == "bar";
}

void testTrue() {
    true.should == true;
    false.should == false;

    true.shouldNot == false;
    false.shouldNot == true;
}


void testCmp() {
    2.should <= 2;
    2.should >= 2;
    2.shouldNot <= 1;
    3.should < 5;
    5.should > 3;
    1.should <= 2;
    1.shouldNot <= 0;
}
