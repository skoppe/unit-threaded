module tests.pass.should;

import unit_threaded;

void testEquals() {
    5.should == 5;
    2.shouldNot == 5;
}
