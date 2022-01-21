
c:
cd \Projects\TWETaxObligation\Source
javac %1.java
copy /Y c:\projects\TWETaxObligation\Source\%1.class c:\projects\TWETaxObligation\eTWETaxObligation
cd \projects\TWETaxObligation
jar -cvf eTWETaxObligation.jar eTWETaxObligation
